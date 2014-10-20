//
//  WLXBluetoohDeviceDiscoverer.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import "WLXBluetoothDeviceDiscoverer.h"
#import "WLXBluetoothDeviceLogger.h"
#import "WLXManagedDelayedExecutor.h"

@interface WLXBluetoothDeviceDiscoverer ()

@property (nonatomic) NSRegularExpression * deviceNameRegex;
@property (nonatomic) NSUInteger timeout;
@property (nonatomic) CBCentralManager * centralManager;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) NSMutableDictionary * discoveredDevicesDictionary;
@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) NSArray * handlers;
@property (nonatomic) WLXManagedDelayedExecutor * discoveryTimerExecutor;
@property BOOL bluetoothOn;


@end

@implementation WLXBluetoothDeviceDiscoverer

@dynamic discoveredDevices;

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                                 queue:(dispatch_queue_t)queue {
    NSAssert(centralManager != nil, @"Central manager cannot be nil");
    self = [super init];
    if (self) {
        _centralManager = centralManager;
        _queue = queue;
        _discovering = NO;
        _bluetoothOn = NO;
        _notificationCenter = notificationCenter;
        _scanOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO};
        _discoveryTimerExecutor = [[WLXManagedDelayedExecutor alloc] initWithQueue:queue];
        [self registerNotificationHandlers];
    }
    return self;
}

- (void)dealloc {
    [self unregisterNotificationHandlers];
}

- (NSArray *)discoveredDevices {
    return [self.discoveredDevicesDictionary allValues];
}

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex
                withServices:(NSArray *)servicesUUIDs
                  andTimeout:(NSUInteger)timeout {
    if (timeout == 0) {
        [NSException raise:@"InvalidTimeoutException" format:@"Timeout must be a positive number"];
    }
    if (!self.bluetoothOn) {
        DDLogDebug(@"Cannot start discovering devices, Bluetooth service is turned off.");
        return NO;
    }
    if (self.discovering) {
        DDLogWarn(@"Cannot start discovering devices, the discovery process has already been started.");
        return NO;
    }
    if (nameRegex != nil) {
        self.deviceNameRegex = [self buildRegularExpression:nameRegex];
    }
    
    DDLogDebug(@"Discovering devices named %@ with service UUIDs %@ and timeout %lu", nameRegex, servicesUUIDs,
               (unsigned long)timeout);
    self.timeout = timeout;
    self.discoveredDevicesDictionary = [[NSMutableDictionary alloc] init];
    [self.centralManager scanForPeripheralsWithServices:servicesUUIDs options:self.scanOptions];
    [self startDiscoveryTerminationTimerWithTimeout:timeout];
    self.discovering = YES;
    [self.notificationCenter postNotificationName:WLXBluetoothDeviceStartDiscovering object:self];
    [self.delegate deviceDiscoverer:self startDiscoveringDevicesWithTimeout:timeout];
    
    return YES;
}

- (void)stopDiscoveringDevices {
    [self.discoveryTimerExecutor invalidateExecutors];
    if (self.discovering) {
        DDLogDebug(@"Stopped discovering devices.");
        [self.centralManager stopScan];
        self.discovering = NO;
        [self.notificationCenter postNotificationName:WLXBluetoothDeviceStoptDiscovering object:self];
        [self.delegate deviceDiscovererStopDiscoveringDevices:self];
    } else {
        DDLogWarn(@"Cannot stop discovering devices, the discovery process has already been stopped.");
    }
}

- (BOOL)addDiscoveredDevice:(WLXDeviceDiscoveryData *)deviceDiscoveryData {
    if (!self.discovering) {
        DDLogWarn(@"Request to add a new discovered device when the app is not discovering devices.");
        return NO;
    }
    if ([self deviceAlreadyDiscovered:deviceDiscoveryData]) {
        DDLogDebug(@"Device %@ with UUID %@ has already been discovered", deviceDiscoveryData.deviceName,
                   deviceDiscoveryData.deviceUUID);
        return NO;
    }
    if (![self discoveredDeviceMatchesRequiredName:deviceDiscoveryData]) {
        DDLogDebug(@"Device %@ that not matches required name %@", deviceDiscoveryData.deviceName,
                   self.deviceNameRegex.pattern);
        return NO;
    }
    self.discoveredDevicesDictionary[deviceDiscoveryData.deviceUUID] = deviceDiscoveryData;
    [self.notificationCenter postNotificationName:WLXBluetoothDeviceDeviceDiscovered
                                           object:self
                                         userInfo:@{WLXBluetoothDeviceDiscoveryData : deviceDiscoveryData}];
    [self.delegate deviceDiscoverer:self discoveredDevice:deviceDiscoveryData];
    
    return YES;
}

#pragma mark - Private methods

- (BOOL)discoveredDeviceMatchesRequiredName:(WLXDeviceDiscoveryData *)discoveryData {
    BOOL matchesName = YES;
    if (self.deviceNameRegex) {
        NSString * deviceName = discoveryData.deviceName;
        NSRange range = NSMakeRange(0, [deviceName length]);
        NSTextCheckingResult * match = [self.deviceNameRegex firstMatchInString:deviceName options:0 range:range];
        matchesName = match != nil;
    }
    return matchesName;
}

- (BOOL)deviceAlreadyDiscovered:(WLXDeviceDiscoveryData *)discoveryData {
    return self.discoveredDevicesDictionary[discoveryData.deviceUUID] != nil;
}

- (void)startDiscoveryTerminationTimerWithTimeout:(NSUInteger)timeout {
    DDLogVerbose(@"Discovery timer started with timeout %lu", (unsigned long)timeout);
    __block typeof(self) this = self;
    [self.discoveryTimerExecutor after:timeout dispatchBlock:^(){
        DDLogDebug(@"Discovery timer has experied");
        if (this.discovering) {
            [this stopDiscoveringDevices];
        }
    }];
}

- (NSRegularExpression *)buildRegularExpression:(NSString *)pattern {
    NSError * error;
    NSRegularExpression * regexp = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                             options:0
                                                                               error:&error];
    NSString * errorMessage = [NSString stringWithFormat:@"Invalid device name regexp: %@", error];
    NSAssert(error == nil, errorMessage);
    return regexp;
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
