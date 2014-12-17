//
//  WLXBluetoothConnectionManager.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#import "WLXBluetoothConnectionManager.h"
#import "WLXBluetoothDeviceLogger.h"
#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceConnectionError.h"
#import "WLXBluetoothDeviceNotifications.h"
#import "WLXReconnectionStrategy.h"
#import "WLXManagedDelayedExecutor.h"

@interface WLXBluetoothConnectionManager ()

@property (nonatomic, copy) void (^connectionBlock)(NSError *);
@property (nonatomic) CBCentralManager * centralManager;
@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) id<WLXReconnectionStrategy> reconnectionStrategy;
@property (nonatomic) BOOL disconnecting;
@property NSArray * handlers;
@property (nonatomic) WLXManagedDelayedExecutor * connectionTimerExecutor;

@end

@implementation WLXBluetoothConnectionManager

@dynamic peripheralUUID;
@dynamic active;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                    centralManager:(CBCentralManager *)centralManager
                notificationCenter:(NSNotificationCenter *)notificationCenter
                             queue:(dispatch_queue_t)queue
              reconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy
                        bluetoohOn:(BOOL)bluetoothOn{
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(centralManager);
    WLXAssertNotNil(notificationCenter);
    self = [super init];
    if (self) {
        _centralManager = centralManager;
        _peripheral = peripheral;
        _notificationCenter = notificationCenter;
        _queue = queue;
        _reconnectionStrategy = reconnectionStrategy;
        _connected = NO;
        _connecting = NO;
        _reconnecting = NO;
        _connectionOptions = nil;
        _disconnecting = NO;
        _bluetoothOn = bluetoothOn;
        _connectionTimerExecutor = [[WLXManagedDelayedExecutor alloc] initWithQueue:queue];
        [self registerNotificationHandlers];
    }
    return self;
}

- (void)dealloc {
    [self unregisterNotificationHandlers];
}

- (NSString *)peripheralUUID {
    return self.peripheral.identifier.UUIDString;
}

- (BOOL)isActive {
    return self.connecting || self.reconnecting || self.connected;
}

- (BOOL)connectWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block {
    if (![self canConnectUsingBlock:block]) {
        return NO;
    }
    
    _connecting = YES;
    self.connectionBlock = block;
    [self.centralManager connectPeripheral:self.peripheral options:self.connectionOptions];
    DDLogDebug(@"Connection with '%@' initiated. Reconnecting '%@'", self.peripheral.name,
               (self.reconnecting) ? @"YES" : @"NO");
    if (timeout > 0) {
        [self startConnectionTerminationTimerWithTimeout:timeout forPeripheral:self.peripheral];
    }
    return YES;
}

- (BOOL)connectWithTimeout:(NSUInteger)timeout {
    return [self connectWithTimeout:timeout usingBlock:nil];
}

- (void)disconnect {
    if (self.connected) {
        DDLogVerbose(@"Disconnecting from device '%@'", self.peripheral.name);
        [self.centralManager cancelPeripheralConnection:self.peripheral];
        self.disconnecting = YES;
    }
}

- (void)didFailToConnect:(NSError *)error {
    NSAssert(self.connecting, @"Cannot call didFailToConnect if connecting is NO");
    [self.connectionTimerExecutor invalidateExecutors];
    if (self.reconnecting) {
        [self tryToReconnect:error];
    } else {
        [self failToConnectWithError:error];
    }
}

- (void)didDisconnect:(NSError *)error {
    if (!self.connected && !self.reconnecting) {
        DDLogDebug(@"Call to didDisconnect ignored because connection manager is neigher connected or reconnecting.");
        return;
    }
    _connected = NO;
    _connecting = NO;
    if (self.disconnecting) {
        NSAssert(error == nil, @"Cannot be an error if disconnecting is YES");
        self.disconnecting = NO;
        if (self.reconnecting) {
            DDLogDebug(@"Reconnection attemp has been terminated.");
        } else {
            DDLogInfo(@"Connection with device '%@' has been terminated.", self.peripheral.name);
            NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : self.peripheral };
            [self.notificationCenter postNotificationName:WLXBluetoothDeviceConnectionTerminated object:self userInfo:userInfo];
            [self.delegate connectionManagerDidTerminateConnection:self];
        }
    } else if (self.reconnecting || error != nil) {
        NSAssert(!self.connected || error != nil, @"There must be an error if disconnecting is NO");
        DDLogInfo(@"Connection with device '%@' has been lost due to an error: %@", self.peripheral.name, error);
        [self tryToReconnect:error];
    } else {
        // This branch is executed because when the connection timer expires the cancelPeripheralConnection:
        // on the CBCentralManager is called and that might result into a call to this methods.
        DDLogDebug(@"Ignoring didDisconnect call because connection manager is trying to reconnect");
    }
}

- (void)didConnect {
    NSAssert(self.connecting, @"Cannot call didConnect if connecting is NO");
    DDLogDebug(@"Connection with peripheral '%@' successfully established. Reconnecting '%@'", self.peripheralUUID,
               (self.reconnecting) ? @"YES" : @"NO");
    [self.connectionTimerExecutor invalidateExecutors];
    NSString * notificationName;
    if (self.reconnecting) {
        notificationName = WLXBluetoothDeviceReconnectionEstablished;
    } else {
        notificationName = WLXBluetoothDeviceConnectionEstablished;
    }
    [self.reconnectionStrategy reset];
    _connected = YES;
    _connecting = NO;
    _reconnecting = NO;
    // We don't want to create a service manager every time a connection is made
    // because all the cached data will be lost if we do so. Using the same instance every time
    // is not a problem because an instance of connection manager always handles the same
    // peripheral therefor the service manager is guaranted to manage the same peripheral.
    if (_servicesManager == nil) {
        _servicesManager = [[WLXServicesManager alloc] initWithPeripheral:self.peripheral
                                                       notificationCenter:self.notificationCenter];
    }
    if (self.connectionBlock) {
        self.connectionBlock(nil);
        self.connectionBlock = nil;
    }
    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : self.peripheral };
    [self.notificationCenter postNotificationName:notificationName object:self userInfo:userInfo];
    if (self.reconnecting && [self.delegate respondsToSelector:@selector(connecitonManagerDidReconnect:)]) {
        [self.delegate connecitonManagerDidReconnect:self];
    } else if (!self.reconnecting) {
        [self.delegate connectionManagerDidConnect:self];
    }
}

#pragma mark - Private methods

- (void)setBluetoothOn:(BOOL)bluetoothOn {
    _bluetoothOn = bluetoothOn;
}

- (void)startConnectionTerminationTimerWithTimeout:(NSUInteger)timeout forPeripheral:(CBPeripheral *)peripheral {
    NSAssert(timeout > 0, @"Timeout must be a positive number.");
    DDLogVerbose(@"Connection timer started with timeout %lu. Connected '%@'. Connecting '%@'. Reconnecting '%@'.",
                 (unsigned long)timeout, (self.connected) ? @"YES" : @"NO", (self.connecting) ? @"YES" : @"NO",
                 (self.reconnecting) ? @"YES" : @"NO");
    
    __block typeof(self) this = self;
    [self.connectionTimerExecutor after:timeout dispatchBlock:^{
        DDLogDebug(@"Connection timer has expired. Connected '%@'. Connecting '%@'. Reconnecting '%@'.",
                   (self.connected) ? @"YES" : @"NO", (self.connecting) ? @"YES" : @"NO",
                   (self.reconnecting) ? @"YES" : @"NO");
        if (!this.connected && (this.connecting || this.reconnecting)) {
            NSError * error = [NSError errorWithDomain:WLXBluetoothDeviceConnectionErrorDomain
                                                  code:WLXBluetoothDeviceConnectionErrorConnectionTimeoutExpired
                                              userInfo:nil];
            if (self.reconnecting) {
                [self tryToReconnect:error];
            } else {
                [self failToConnectWithError:error];
            }
            self.disconnecting = YES;
            [this.centralManager cancelPeripheralConnection:peripheral];
        }
    }];
}

- (void)failToConnectWithError:(NSError *)error {
    _connected = NO;
    _connecting = NO;
    _reconnecting = NO;
    if (self.connectionBlock) {
        self.connectionBlock(error);
        self.connectionBlock = nil;
    }
    NSDictionary * userInfo = @{ WLXBluetoothDeviceError : error };
    [self.notificationCenter postNotificationName:WLXBluetoothDeviceFailToConnect object:self userInfo:userInfo];
    [self.delegate connectionManager:self didFailToConnect:error];
}

- (BOOL)canConnectUsingBlock:(void(^)(NSError *))block {
    if (!self.bluetoothOn) {
        DDLogDebug(@"Connection with peripheral, connection could not be initiated because Bluetooth service is not available.");
        if (block) {
            block(WLXBluetoothNotAvailableError());
        }
        return NO;
    }
    if (self.connecting) {
        DDLogWarn(@"Connection with peripheral '%@' could not be initiated because a connection has already been started.",
                  self.peripheral.name);
        if (block) {
            block(WLXConnectionAlreadyStartedError());
        }
        return NO;
    }
    if (self.connected) {
        DDLogWarn(@"Connection could not be initiated because a previous connection with '%@' is still active.",
                  self.peripheral.name);
        if (block) {
            block(WLXAlreadyConnectedError());
        }
        return NO;
    }
    return YES;
}

- (void)tryToReconnect:(NSError *)error {
    _reconnecting = YES;
    __block typeof(self) this = self;
    BOOL willTryToReconnect = [self.reconnectionStrategy tryToReconnectUsingConnectionBlock:^{
        [this connectWithTimeout:this.reconnectionStrategy.connectionTimeout usingBlock:nil];
    }];
    if (!willTryToReconnect) {
        _reconnecting = NO;
        NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : self.peripheral, WLXBluetoothDeviceError : error };
        [self.notificationCenter postNotificationName:WLXBluetoothDeviceConnectionLost object:self userInfo:userInfo];
        [self.delegate connectionManager:self didLostConnection:error];
    } else {
        NSUInteger remainingAttemps = self.reconnectionStrategy.remainingConnectionAttempts;
        NSDictionary * userInfo = @{
            WLXBluetoothDeviceRemainingReconnectionAttemps : @(remainingAttemps)
        };
        [self.notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:this userInfo:userInfo];
        if ([self.delegate respondsToSelector:@selector(connectionManager:willAttemptToReconnect:)]) {
            [self.delegate connectionManager:self willAttemptToReconnect:remainingAttemps];
        }
    }
}

- (void)registerNotificationHandlers {
    __block typeof(self) this = self;
    self.handlers = @[
        [self.notificationCenter addObserverForName:WLXBluetoothDeviceBluetoothIsOn
                                             object:nil
                                              queue:nil
                                         usingBlock:^(NSNotification * notification){
                                             this.bluetoothOn = YES;
                                         }],
        [self.notificationCenter addObserverForName:WLXBluetoothDeviceBluetoothIsOff
                                             object:nil
                                              queue:nil
                                         usingBlock:^(NSNotification * notification){
                                             this.bluetoothOn = NO;
                                         }]
    ];
}

- (void)unregisterNotificationHandlers {
    for (id handler in self.handlers) {
        [self.notificationCenter removeObserver:handler];
    }
}

@end
