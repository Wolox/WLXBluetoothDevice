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
#import "WLXBluetoothConnectionManager.h"
#import "WLXBluetoothDeviceDiscoverer.h"
#import "WLXBluetoothDeviceConnectionError.h"
#import "WLXLinearReconnectionStrategy.h"
#import "WLXCentralManagerDelegate.h"

// Dispatch Queue for Bluetooth connection with Trakr
static dispatch_queue_t defaultDeviceQueue = NULL;
static const char * const kDefaultDeviceQueueName = "ar.com.wolox.BluetoothDeviceQueue";

@interface WLXBluetoothDeviceManager ()

@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) WLXCentralManagerDelegate * centralManagerDelegate;

@end

@implementation WLXBluetoothDeviceManager

@dynamic bluetoothOn;

DYNAMIC_LOGGER_METHODS

+ (void)initialize {
    defaultDeviceQueue = dispatch_queue_create(kDefaultDeviceQueueName, DISPATCH_QUEUE_SERIAL);
}

+ (instancetype)deviceManager {
    return [WLXBluetoothDeviceManager deviceManagerWithQueue:defaultDeviceQueue];
}

+ (instancetype)deviceManagerWithQueue:(dispatch_queue_t)queue {
    NSDictionary * options = @{CBCentralManagerOptionShowPowerAlertKey: @YES};
    CBCentralManager * centralManager = [[CBCentralManager alloc] initWithDelegate:nil queue:queue options:options];
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    return [[WLXBluetoothDeviceManager alloc] initWithCentralManager:centralManager
                                                  notificationCenter:notificationCenter
                                                               queue:queue];
}

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                                 queue:(dispatch_queue_t)queue {
    WLXAssertNotNil(centralManager);
    WLXAssertNotNil(notificationCenter);
    self = [super init];
    if (self) {
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

- (BOOL)isBluetoothOn {
    return self.centralManagerDelegate.bluetoothOn;
}

- (id<WLXConnectionManager>)connectionManagerForPeripheral:(CBPeripheral *)peripheral
                                 usingReconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy {
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(reconnectionStrategy);
    id connectionManager = [[WLXBluetoothConnectionManager alloc] initWithPeripheral:peripheral
                                                                      centralManager:self.centralManager
                                                                  notificationCenter:self.notificationCenter
                                                                               queue:self.queue
                                                                reconnectionStrategy:reconnectionStrategy
                                                                          bluetoohOn:self.bluetoothOn];
    [self.centralManagerDelegate registerConnectionManager:connectionManager];
    return connectionManager;
}

- (WLXBluetoothDeviceRegistry *)deviceRegistryWithRepository:(id<WLXBluetoothDeviceRepository>)repository {
    return [[WLXBluetoothDeviceRegistry alloc] initWithRepository:repository
                                               notificationCenter:self.notificationCenter
                                                   centralManager:self.centralManager];
}

@end
