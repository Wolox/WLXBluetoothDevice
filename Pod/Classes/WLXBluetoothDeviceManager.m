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
#import "WLXBluetoothDeviceDiscoverer.h"
#import "WLXBluetoothDeviceConnectionError.h"
#import "WLXLinearReconnectionStrategy.h"
#import "WLXCentralManagerDelegate.h"

// Dispatch Queue for Bluetooth connection with Trakr
static dispatch_queue_t defaultDeviceQueue = NULL;
static const char * const kDefaultDeviceQueueName = "ar.com.wolox.BluetoothDeviceQueue";

@interface WLXBluetoothDeviceManager () {
    CBPeripheral * _lastConnectedPeripheral;
}

@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) id<WLXBluetoothDeviceRepository> repository;
@property (nonatomic) WLXCentralManagerDelegate * centralManagerDelegate;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation WLXBluetoothDeviceManager

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
        _discoverer = [[WLXBluetoothDeviceDiscoverer alloc] initWithCentralManager:centralManager
                                                                notificationCenter:notificationCenter
                                                                             queue:queue];
        _centralManagerDelegate = [[WLXCentralManagerDelegate alloc] initWithDiscoverer:_discoverer
                                                                     notificationCenter:notificationCenter];
        _centralManager = centralManager;
        _centralManager.delegate = _centralManagerDelegate;
        
    }
    return self;
}

- (id<WLXConnectionManager>)connectionManagerForPeripheral:(CBPeripheral *)peripheral
                                 usingReconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy {
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(reconnectionStrategy);
    id connectionManager = [[WLXBluetoothConnectionManager alloc] initWithPeripheral:peripheral
                                                                      centralManager:self.centralManager
                                                                  notificationCenter:self.notificationCenter
                                                                               queue:self.queue
                                                                reconnectionStrategy:reconnectionStrategy];
    [self.centralManagerDelegate registerConnectionManager:connectionManager];
    return connectionManager;
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

- (void)setLastConnectedPeripheral:(CBPeripheral *)lastConnectedPeripheral {
    _lastConnectedPeripheral = lastConnectedPeripheral;
    [self saveLastConnectedPeripheral:lastConnectedPeripheral];
}

#pragma mark - Private methods

- (CBPeripheral *)loadLastConnectedPeripheral {
    NSArray * UUIDs = @[[[NSUUID alloc] initWithUUIDString:self.lastConnectionRecord.UUID]];
    NSArray * peripherals = [self.centralManager retrieveConnectedPeripheralsWithServices:UUIDs];
    return [peripherals firstObject];
}

- (void)saveLastConnectedPeripheral:(CBPeripheral *)peripheral {
    [self.repository saveConnectionRecord:[WLXBluetoothDeviceConnectionRecord recordWithPeripheral:peripheral]];
}

@end
