//
//  WLXServiceManager.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import "WLXServicesManager.h"

#import "WLXBluetoothDeviceLogger.h"
#import "WLXBluetoothDeviceHelpers.h"
#import "WLXServicesManager.h"
#import "WLXBluetoothDeviceNotifications.h"

NSString * const WLXBluetoothDeviceServiceErrorDomain = @"ar.com.wolox.WLXBluetoothDevice.ServiceErrorDomain";


@interface WLXServicesManager ()

@property (nonatomic) NSMutableDictionary * servicesByUUID;
@property (nonatomic) CBPeripheral * peripheral;
@property (nonatomic) NSMutableDictionary * managers;
@property (nonatomic) NSMutableDictionary * managersByCharacteristic;
@property (nonatomic, copy) void(^discoveryBlock)(NSError *);
@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) NSMutableArray * observers;

@end

@implementation WLXServicesManager

@dynamic services;
@dynamic servicesDiscovered;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                notificationCenter:(NSNotificationCenter *)notificationCenter {
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(notificationCenter);
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _notificationCenter = notificationCenter;
        _servicesByUUID = [[NSMutableDictionary alloc] init];
        _managers = [[NSMutableDictionary alloc] init];
        _managersByCharacteristic = [[NSMutableDictionary alloc] init];
        _discovering = NO;
        _observers = [[NSMutableArray alloc] init];
        [self registerNotificationHandlers];
    }
    return self;
}

- (void)dealloc {
    [self unregisterNotificationHandlers];
}

- (NSArray *)services {
    NSArray * services = self.peripheral.services;
    return (services != nil) ? services : @[];
}

- (BOOL)servicesDiscovered {
    return self.services.count > 0;
}

- (BOOL)discoverServicesUsingBlock:(void(^)(NSError *))block {
    if (self.discovering) {
        if (block) {
            NSError * error = [NSError errorWithDomain:WLXBluetoothDeviceServiceErrorDomain
                                                  code:WLXBluetoothDeviceServiceErrorServicesDiscoveryAlreadyStarted
                                              userInfo:nil];
            block(error);
        }
        DDLogDebug(@"Cannot discover services, the discovery process has already been started.");
        return NO;
    }
    if (block) {
        self.discoveryBlock = block;
    }
    _discovering = YES;
    DDLogDebug(@"Discovering services for peripheral %@", self.peripheral.identifier.UUIDString);
    self.peripheral.delegate = self;
    [self.peripheral discoverServices:nil];
    return YES;
}

- (BOOL)discoverServices {
    return [self discoverServicesUsingBlock:nil];
}

- (CBService *)serviceFromUUID:(CBUUID *)serviceUUID {
    WLXAssertNotNil(serviceUUID);
    return self.servicesByUUID[serviceUUID];
}

- (WLXServiceManager *)managerForService:(CBUUID *)serviceUUID {
    WLXAssertNotNil(serviceUUID);
    return self.managers[serviceUUID];
}


#pragma mark - CBPeripheralDelegate methods

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    _discovering = NO;
    if (!error) {
        [self createManagers];
        [self registerDiscoveredServices];
    } else {
        DDLogDebug(@"Services could not be discovered: %@", error);
    }

    if (self.discoveryBlock) {
        self.discoveryBlock(error);
    }
    self.discoveryBlock = nil;
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    WLXServiceManager * manager = self.managers[service.UUID];
    if (error) {
        [manager failToDiscoverCharacteristics:error];
    } else {
        [self associateManager:manager withCharacteristicsForService:service];
        [manager didDiscoverCharacteristics];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    WLXServiceManager * manager = self.managersByCharacteristic[characteristic.UUID];
    [manager didUpdateValueForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    WLXServiceManager * manager = self.managersByCharacteristic[characteristic.UUID];
    [manager didWriteValueForCharacteristic:characteristic error:error];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    WLXServiceManager * manager = self.managersByCharacteristic[characteristic.UUID];
    [manager didUpdateNotificationStateForCharacteristic:characteristic error:error];
}

#pragma mark - Private methods

- (void)registerDiscoveredServices {
    for (CBService * service in self.peripheral.services) {
        self.servicesByUUID[service.UUID] = service;
    }
}

- (void)associateManager:(WLXServiceManager *)manager withCharacteristicsForService:(CBService *)service {
    WLXAssertNotNil(service);
    if (manager == nil) {
        return;
    }
    for (CBCharacteristic * characteristic in service.characteristics) {
        self.managersByCharacteristic[characteristic.UUID] = manager;
    }
}

- (void)createManagers {
    for (CBService * service in self.peripheral.services) {
        if (self.managers[service.UUID] != nil) {
            DDLogVerbose(@"Manager for service %@ and peripheral %@ has already been created", service.UUID.UUIDString,
                         self.peripheral.identifier.UUIDString);
        } else {
            DDLogDebug(@"Creating service manager for service %@ and peripheral %@", service.UUID.UUIDString,
                       self.peripheral.identifier.UUIDString);
            WLXServiceManager * manager = [[WLXServiceManager alloc] initWithPeripheral:self.peripheral service:service];
            self.managers[service.UUID] = manager;
        }
    }
}

- (void)stopDiscoveringServices {
    _discovering = NO;
    DDLogDebug(@"Stopped discovering services for peripheral %@", self.peripheral.identifier.UUIDString);
}

- (void)registerNotificationHandlers {
    __block typeof(self) this = self;
    id handler = ^(NSNotification * notification) { [this stopDiscoveringServices]; };
    [self registerHandler:handler forNotifications:@[
        WLXBluetoothDeviceBluetoothIsOff,
        WLXBluetoothDeviceConnectionTerminated,
        WLXBluetoothDeviceConnectionLost,
        WLXBluetoothDeviceReconnecting
    ]];
}

- (void)registerHandler:(void(^)(NSNotification *))handler forNotifications:(NSArray *)notifications {
    for (NSString * notification in notifications) {
        [self registerHandler:handler forNotification:notification];
    }
}

- (void)registerHandler:(void(^)(NSNotification *))handler forNotification:(NSString *)notification {
    id observer = [self.notificationCenter addObserverForName:notification
                                                       object:nil
                                                        queue:nil
                                                   usingBlock:handler];
    [self.observers addObject:observer];
}

- (void)unregisterNotificationHandlers {
    for (id observer in self.observers) {
        [self.notificationCenter removeObserver:observer];
    }
}

@end