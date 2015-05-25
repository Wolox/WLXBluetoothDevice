//
//  WLXBluetoothDeviceRegistry.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/5/14.
//
//

#import "WLXBluetoothDeviceRegistry.h"

#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceNotifications.h"

@interface WLXBluetoothDeviceRegistry (){
    CBPeripheral * _lastConnectedPeripheral;
}

@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) id<WLXBluetoothDeviceRepository> repository;
@property (nonatomic) NSArray * notificationHandlers;
@property (nonatomic) CBCentralManager * centralManager;

@end

@implementation WLXBluetoothDeviceRegistry

@dynamic lastConnectedPeripheral;
@dynamic lastConnectionRecord;

- (instancetype)initWithRepository:(id<WLXBluetoothDeviceRepository>)repository
                notificationCenter:(NSNotificationCenter * )notificationCenter
                    centralManager:(CBCentralManager *)centralManager {
    WLXAssertNotNil(repository);
    WLXAssertNotNil(notificationCenter);
    WLXAssertNotNil(centralManager);
    self = [super init];
    if (self) {
        _repository = repository;
        _notificationCenter = notificationCenter;
        _centralManager = centralManager;
        _enabled = NO;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled == enabled) {
        return;
    }
    _enabled = enabled;
    if (enabled) {
        [self registerNotificationHandlers];
    } else {
        [self unregisterNotificationHandlers];
    }
}

- (WLXBluetoothDeviceConnectionRecord *)lastConnectionRecord {
    return [self.repository fetchLastConnectionRecord];
}

- (CBPeripheral *)lastConnectedPeripheral {
    if (_lastConnectedPeripheral == nil) {
        _lastConnectedPeripheral = [self loadLastConnectedPeripheral];
    }
    return _lastConnectedPeripheral;
}

#pragma mark - Private methods

- (void)setLastConnectedPeripheral:(CBPeripheral *)lastConnectedPeripheral {
    _lastConnectedPeripheral = lastConnectedPeripheral;
    [self saveLastConnectedPeripheral:lastConnectedPeripheral];
}

- (CBPeripheral *)loadLastConnectedPeripheral {
    NSArray * UUIDs = @[[[NSUUID alloc] initWithUUIDString:self.lastConnectionRecord.UUID]];
    NSArray * peripherals = [self.centralManager retrievePeripheralsWithIdentifiers:UUIDs];
    return [peripherals firstObject];
}

- (void)saveLastConnectedPeripheral:(CBPeripheral *)peripheral {
    [self.repository saveConnectionRecord:[WLXBluetoothDeviceConnectionRecord recordWithPeripheral:peripheral]];
}

- (void)registerNotificationHandlers {
    __weak typeof(self) wself = self;
    self.notificationHandlers = @[
        [self.notificationCenter addObserverForName:WLXBluetoothDeviceConnectionEstablished
                                             object:nil
                                              queue:nil
                                         usingBlock:^(NSNotification * notification){
                                             CBPeripheral * peripheral = notification.userInfo[WLXBluetoothDevicePeripheral];
                                             __strong typeof(self) this = wself;
                                             [this saveLastConnectedPeripheral:peripheral];
                                         }]
    ];
}

- (void)unregisterNotificationHandlers {
    for (id handler in self.notificationHandlers) {
        [self.notificationCenter removeObserver:handler];
    }
}


@end
