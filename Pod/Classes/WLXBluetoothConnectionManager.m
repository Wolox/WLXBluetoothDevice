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

@interface WLXBluetoothConnectionManager ()

@property (nonatomic, copy) void (^connectionBlock)(NSError *);
@property (nonatomic) CBCentralManager * centralManager;
@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) id<WLXReconnectionStrategy> reconnectionStrategy;
@property (nonatomic) BOOL disconnecting;
@property (nonatomic) BOOL bluetoothOn;
@property NSArray * handlers;

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
    DDLogDebug(@"Connection with '%@' initiated.", self.peripheral.name);
    if (timeout > 0) {
        [self startConnectionTerminationTimerWithTimeout:timeout forPeripheral:self.peripheral];
    }
    return YES;
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
    [self failToConnectWithError:error];
}

- (void)didDisconnect:(NSError *)error {
    NSAssert(self.connected, @"Cannot call didDisconnect if connected is NO");
    _connected = NO;
    _connecting = NO;
    if (self.disconnecting) {
        NSAssert(error == nil, @"Cannot be an error if disconnecting is YES");
        self.disconnecting = NO;
        DDLogInfo(@"Connection with device '%@' has been terminated.", self.peripheral.name);
        NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : self.peripheral };
        [self.notificationCenter postNotificationName:WLXBluetoothDeviceConnectionTerminated object:self userInfo:userInfo];
    } else {
        NSAssert(error != nil, @"There must be an error if disconnecting is NO");
        DDLogInfo(@"Connection with device '%@' has been lost due to an error: %@", self.peripheral.name, error);
        [self tryToReconnect:(NSError *)error];
    }
}

- (void)didConnect {
    NSAssert(self.connecting, @"Cannot call didConnect if connecting is NO");
    _connected = YES;
    _connecting = NO;
    _reconnecting = NO;
    if (self.connectionBlock) {
        self.connectionBlock(nil);
        self.connectionBlock = nil;
    }
    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : self.peripheral };
    [self.notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished object:self userInfo:userInfo];
}

#pragma mark - Private methods

- (void)startConnectionTerminationTimerWithTimeout:(NSUInteger)timeout forPeripheral:(CBPeripheral *)peripheral {
    NSAssert(timeout > 0, @"Timeout must be a positive number.");
    DDLogVerbose(@"Connection timer started with timeout %lul", (unsigned long)timeout);
    __block typeof(self) this = self;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_MSEC));
    dispatch_after(delayTime, self.queue, ^{
        DDLogDebug(@"Connection timer has experied");
        if (!this.connected && this.connecting) {
            NSError * error = [NSError errorWithDomain:WLXBluetoothDeviceConnectionErrorDomain
                                                  code:WLXBluetoothDeviceConnectionErrorConnectionTimeoutExpired
                                              userInfo:nil];
            [self failToConnectWithError:error];
            [this.centralManager cancelPeripheralConnection:peripheral];
        }
    });
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
    __block typeof(self) this = self;
    BOOL willTryToReconnect = [self.reconnectionStrategy tryToReconnectUsingConnectionBlock:^{
        NSDictionary * userInfo = @{
            WLXBluetoothDeviceRemainingReconnectionAttemps : @(this.reconnectionStrategy.remainingConnectionAttempts)
        };
        [this.notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:this userInfo:userInfo];
        [this connectWithTimeout:this.reconnectionStrategy.connectionTimeout usingBlock:nil];
    }];
    if (!willTryToReconnect) {
        NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : self.peripheral, WLXBluetoothDeviceError : error };
        [self.notificationCenter postNotificationName:WLXBluetoothDeviceConnectionLost object:self userInfo:userInfo];
        _reconnecting = NO;
    } else {
        _reconnecting = YES;
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
