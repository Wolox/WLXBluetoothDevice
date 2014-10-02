//
//  WLXBluetoothDeviceManager.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import "WLXBluetoothDeviceManager.h"
#import "WLXBluetoothDeviceDiscoverer.h"
#import "WLXBluetoothDeviceLogger.h"
#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceUserDefaultsRepository.h"
#import "WLXBluetoothConnectionManager.h"
#import "WLXBluetoothDeviceConnectionError.h"
#import "WLXLinearReconnectionStrategy.h"

// Dispatch Queue for Bluetooth connection with Trakr
static dispatch_queue_t defaultDeviceQueue = NULL;
static const char * const kDefaultDeviceQueueName = "ar.com.wolox.BluetoothDeviceQueue";

static NSUInteger DEFAULT_MAX_RECONNECTION_ATTEMPS = 3;

static NSUInteger RECONNECTION_WAIT_TIME = 2000; //ms

@interface WLXBluetoothDeviceManager ()<CBCentralManagerDelegate> {
    CBPeripheral * _lastConnectedPeripheral;
}

@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) id<WLXBluetoothDeviceRepository> repository;
@property (nonatomic) WLXBluetoothDeviceDiscoverer * discoverer;
@property (nonatomic) WLXBluetoothConnectionManager * connectionManager;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) BOOL connecting;
@property BOOL bluetoothOn;

@end

@implementation WLXBluetoothDeviceManager

@dynamic discovering;
@dynamic connected;
@dynamic connectedPeripheral;
@dynamic lastConnectedPeripheral;
@dynamic lastConnectionRecord;

+ (void)initialize {
    defaultDeviceQueue = dispatch_queue_create(kDefaultDeviceQueueName, NULL);
}

+ (instancetype)deviceManager {
    return [WLXBluetoothDeviceManager deviceManagerWithQueue:defaultDeviceQueue];
}

+ (instancetype)deviceManagerWithQueue:(dispatch_queue_t)queue {
    NSDictionary * options = @{CBCentralManagerOptionShowPowerAlertKey: @YES};
    CBCentralManager * centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:queue options:options];
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    id repository = [[WLXBluetoothDeviceUserDefaultsRepository alloc] initWithUserDefaults:userDefaults];
    return [[WLXBluetoothDeviceManager alloc] initWithCentralManager:centralManager
                                                  notificationCenter:notificationCenter
                                                          repository:repository
                                                               queue:queue];
}

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                            repository:(id<WLXBluetoothDeviceRepository>)repository
                                 queue:(dispatch_queue_t)queue {
    WLXAssertNotNil(centralManager);
    WLXAssertNotNil(notificationCenter);
    WLXAssertNotNil(repository);
    self = [super init];
    if (self) {
        _repository = repository;
        _notificationCenter = notificationCenter;
        _queue = queue;
        _centralManager = centralManager;
        _centralManager.delegate = self;
        _maxReconnectionAttempts = DEFAULT_MAX_RECONNECTION_ATTEMPS;
        _bluetoothOn = NO;
    }
    return self;
}

#pragma mark - Discovery management

- (BOOL)isDiscovering {
    return self.discoverer != nil && self.discoverer.discovering;
}

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex withServices:(NSArray *)servicesUUIDs andTimeout:(NSUInteger)timeout {
    if (!self.bluetoothOn) {
        DDLogDebug(@"Cannot start discovery process because Bluetooth service is not available.");
        return NO;
    }
    self.discoverer = [[WLXBluetoothDeviceDiscoverer alloc] initWithCentralManager:self.centralManager
                                                                notificationCenter:self.notificationCenter
                                                                             queue:self.queue];
    return [self.discoverer discoverDevicesNamed:nameRegex withServices:servicesUUIDs andTimeout:timeout];
}

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex andTimeout:(NSUInteger)timeout {
    return [self discoverDevicesNamed:nameRegex withServices:nil andTimeout:timeout];
}

- (BOOL)discoverDevicesWithTimeout:(NSUInteger)timeout {
    return [self discoverDevicesNamed:nil andTimeout:timeout];
}

- (void)stopDiscoveringDevices {
    [self.discoverer stopDiscoveringDevices];
    self.discoverer = nil;
}

#pragma mark - Connection management

- (WLXBluetoothDeviceConnectionRecord *)lastConnectionRecord {
    return [self.repository fetchLastConnectionRecord];
}

- (CBPeripheral *)lastConnectedPeripheral {
    if (_lastConnectedPeripheral == nil) {
        _lastConnectedPeripheral = [self loadLastConnectedPeripheral];
    }
    return _lastConnectedPeripheral;
}

- (BOOL)isConnected {
    return self.connectionManager != nil && self.connectionManager.connected;
}

- (BOOL)isConnecting {
    return self.connectionManager != nil && self.connectionManager.connecting;
}

- (CBPeripheral *)connectedPeripheral {
    CBPeripheral * peripheral = nil;
    if (self.connected) {
        peripheral = self.connectionManager.peripheral;
    }
    return peripheral;
}

- (void)setLastConnectedPeripheral:(CBPeripheral *)lastConnectedPeripheral {
    _lastConnectedPeripheral = lastConnectedPeripheral;
    [self saveLastConnectedPeripheral:lastConnectedPeripheral];
}

- (BOOL)connectWithPeripheral:(CBPeripheral *)peripheral timeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block {
    WLXAssertNotNil(peripheral);
    if (![self canConnectWithPeripheral:peripheral usingBlock:block]) {
        return NO;
    }
    id reconnectionStrategy = [[WLXLinearReconnectionStrategy alloc] initWithWaitTime:RECONNECTION_WAIT_TIME
                                                              maxReconnectionAttempts:self.maxReconnectionAttempts
                                                                    connectionTimeout:timeout
                                                                                queue:self.queue];
    self.connectionManager = [[WLXBluetoothConnectionManager alloc] initWithPeripheral:peripheral
                                                                        centralManager:self.centralManager
                                                                    notificationCenter:self.notificationCenter
                                                                                 queue:self.queue
                                                                  reconnectionStrategy:reconnectionStrategy];
    return [self.connectionManager connectWithTimeout:timeout usingBlock:block];
}

- (BOOL)connectWithPeripheral:(CBPeripheral *)peripheral timeout:(NSUInteger)timeout {
    return [self connectWithPeripheral:peripheral timeout:timeout usingBlock:nil];
}

- (BOOL)connectWithPeripheral:(CBPeripheral *)peripheral {
    return [self connectWithPeripheral:peripheral timeout:0];
}

- (BOOL)connectWithLastDeviceWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block {
    if (self.lastConnectedPeripheral == nil) {
        DDLogDebug(@"Last connected peripheral is nil");
        if (block) {
            block(WLXLastConnectedPeripheralNotAvailableError());
        }
        return NO;
    }
    return [self connectWithPeripheral:self.lastConnectedPeripheral timeout:timeout usingBlock:block];
}

- (BOOL)connectWithLastDeviceWithTimeout:(NSUInteger)timeout {
    return [self connectWithLastDeviceWithTimeout:timeout usingBlock:nil];
}

- (BOOL)connectWithLastDevice {
    return [self connectWithLastDeviceWithTimeout:0];
}

- (void)disconnect {
    if (self.connected) {
        DDLogVerbose(@"Disconnecting from device '%@'", self.connectedPeripheral.name);
        [self.centralManager cancelPeripheralConnection:self.connectedPeripheral];
    }
}

# pragma mark - CBCentralManagerDelegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            DDLogDebug(@"The Bluetooth manager state is unknown");
            self.bluetoothOn = NO;
            break;
        case CBCentralManagerStateResetting:
            DDLogDebug(@"The Bluetooth connection was temporaly lost.");
            self.bluetoothOn = NO;
            break;
        case CBCentralManagerStateUnsupported:
            DDLogDebug(@"Bluetooth Low Energy is not supported on this platform");
            self.bluetoothOn = NO;
            break;
        case CBCentralManagerStateUnauthorized:
            DDLogDebug(@"This app is not authorized to use Bluetooth");
            self.bluetoothOn = NO;
            // TODO Notify the delegate that the app is not authorized to use bluetooth
            break;
        case CBCentralManagerStatePoweredOn:
            DDLogDebug(@"Bluetooh is turned on");
            self.bluetoothOn = YES;
            [self.notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOn object:self];
            break;
        case CBCentralManagerStatePoweredOff:
            DDLogDebug(@"Bluetooth is turned off");
            self.bluetoothOn = NO;
            [self.notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOff object:self];
            break;
        default:
            DDLogDebug(@"Central Manager did change state to %ld", (long)central.state);
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    WLXDeviceDiscoveryData * data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral
                                                                     advertisementData:advertisementData
                                                                                  RSSI:RSSI];
    [self.discoverer addDiscoveredDevice:data];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    [self.connectionManager didConnect];
    [self setLastConnectedPeripheral:peripheral];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    [self.connectionManager didFailToConnect:error];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    [self.connectionManager didDisconnect:error];
}

#pragma mark - Private methods

- (BOOL)canConnectWithPeripheral:(CBPeripheral *)peripheral usingBlock:(void(^)(NSError *))block {
    if (!self.bluetoothOn) {
        DDLogDebug(@"Connection with peripheral '%@' could not be initiated because Bluetooth service is not available.",
                  peripheral.name);
        if (block) {
            block(WLXBluetoothNotAvailableError());
        }
        return NO;
    }
    if (self.connected) {
        DDLogWarn(@"Connection with peripheral '%@' could not be initiated because a previous connection with '%@' is still active.",
                  peripheral.name, self.connectedPeripheral.name);
        if (block) {
            block(WLXAlreadyConnectedError());
        }
        return NO;
    }
    if (self.connecting) {
        DDLogWarn(@"Connection with peripheral '%@' could not be initiated because a connection has already been started.",
                  peripheral.name);
        if (block) {
            block(WLXConnectionAlreadyStartedError());
        }
        return NO;
    }
    return YES;
}

- (CBPeripheral *)loadLastConnectedPeripheral {
    NSArray * UUIDs = @[[[NSUUID alloc] initWithUUIDString:self.lastConnectionRecord.UUID]];
    NSArray * peripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:UUIDs];
    return [peripherals firstObject];
}

- (void)saveLastConnectedPeripheral:(CBPeripheral *)peripheral {
    [self.repository saveConnectionRecord:[WLXBluetoothDeviceConnectionRecord recordWithPeripheral:peripheral]];
}

@end
