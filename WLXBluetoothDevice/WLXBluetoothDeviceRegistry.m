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
#import "WLXBluetoothDeviceLogger.h"

@interface WLXBluetoothDeviceRegistry (){
    CBPeripheral * _lastConnectedPeripheral;
}

@property (nonatomic) NSNotificationCenter * notificationCenter;
@property (nonatomic) id<WLXBluetoothDeviceRepository> repository;
@property (nonatomic) NSArray * notificationHandlers;
@property (nonatomic) CBCentralManager * centralManager;

@end

@implementation WLXBluetoothDeviceRegistry

WLX_BD_DYNAMIC_LOGGER_METHODS

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

- (void)fetchLastConnectedPeripheralWithBlock:(void(^)(NSError *, CBPeripheral *))block {
    WLXAssertNotNil(block);
    [self fetchLastConnectionRecordWithBlock:^(NSError * error, WLXBluetoothDeviceConnectionRecord * record) {
        if (error) {
            block(error, nil);
        } else {
            block(nil, [record loadPeripheralFromCentral:self.centralManager]);
        }
    }];
}

#pragma mark - WLXBluetoothDeviceRepository

- (void)fetchLastConnectionRecordWithBlock:(void(^)(NSError *, WLXBluetoothDeviceConnectionRecord *))block {
    [self.repository fetchLastConnectionRecordWithBlock:block];
}

- (void)fetchConnectionRecordsWithBlock:(void (^)(NSError *, NSArray *))block {
    [self.repository fetchConnectionRecordsWithBlock:block];
}

- (void)deleteConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord withBlock:(void(^)(NSError *))block {
    [self.repository deleteConnectionRecord:connectionRecord withBlock:block];
}

- (void)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord withBlock:(void (^)(NSError *))block {
    [self.repository saveConnectionRecord:connectionRercord withBlock:block];
}

#pragma mark - Private methods

- (void)setLastConnectedPeripheral:(CBPeripheral *)lastConnectedPeripheral {
    _lastConnectedPeripheral = lastConnectedPeripheral;
    [self saveLastConnectedPeripheral:lastConnectedPeripheral];
}


- (void)saveLastConnectedPeripheral:(CBPeripheral *)peripheral {
    id record = [WLXBluetoothDeviceConnectionRecord recordWithPeripheral:peripheral];
    [self.repository saveConnectionRecord:record withBlock:^(NSError * error) {
        WLXLogError(@"Connection record could not be saved: %@", error);
    }];
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
