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

NSString * const WLXBluetoothDeviceServiceErrorDomain = @"ar.com.wolox.WLXBluetoothDevice.ServiceErrorDomain";


@interface WLXServicesManager ()

@property (nonatomic) NSMutableDictionary * servicesByUUID;
@property (nonatomic) CBPeripheral * peripheral;
@property (nonatomic) NSMutableDictionary * managers;
@property (nonatomic) NSMutableDictionary * managersByCharacteristic;
@property (nonatomic) BOOL discovering;
@property (nonatomic, copy) void(^discoveryBlock)(NSError *);

@end

@implementation WLXServicesManager

@dynamic services;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
    WLXAssertNotNil(peripheral);
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _servicesByUUID = [[NSMutableDictionary alloc] init];
        _managers = [[NSMutableDictionary alloc] init];
        _managersByCharacteristic = [[NSMutableDictionary alloc] init];
        _discovering = NO;
    }
    return self;
}

- (NSArray *)services {
    NSArray * services = self.peripheral.services;
    return (services != nil) ? services : @[];
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
    self.discovering = YES;
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
    self.discovering = NO;
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
        DDLogVerbose(@"Creating service manager for service %@ and peripheral %@", service.UUID.UUIDString,
                     self.peripheral.identifier.UUIDString);
        WLXServiceManager * manager = [[WLXServiceManager alloc] initWithPeripheral:self.peripheral service:service];
        self.managers[service.UUID] = manager;
    }
}

@end
