//
//  WLXServiceManager.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import "WLXServiceManager.h"

#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceLogger.h"

static NSString * createQueueName(CBPeripheral * peripheral) {
    return [NSString stringWithFormat:@"ar.com.wolox.WLXBluetoothDevice.WLXServiceManager.%@",
            peripheral.identifier.UUIDString];
}

@interface WLXServiceManager ()

@property (nonatomic) CBPeripheral * peripheral;
@property (nonatomic) CBService * service;
@property (nonatomic) NSMutableDictionary * characteristicByUUID;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) NSString * queueName;
@property (nonatomic) NSMutableDictionary * observers;
@property (nonatomic) NSMutableDictionary * readHandlerBlockQueues;
@property (nonatomic) NSMutableDictionary * writeHandlerBlockQueues;
@property (nonatomic) NSMutableDictionary * stateChangeHandlerBlockQueues;
@property (nonatomic) NSMutableDictionary * pendingOperationPerCharacteristicUUID;

@end

@implementation WLXServiceManager

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral service:(CBService *)service {
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(service);
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _service = service;
        _characteristicByUUID = [[NSMutableDictionary alloc] init];
        _observers = [[NSMutableDictionary alloc] init];
        _queueName = createQueueName(peripheral);
        _queue = dispatch_queue_create([_queueName cStringUsingEncoding:NSASCIIStringEncoding], NULL);
        _readHandlerBlockQueues = [[NSMutableDictionary alloc] init];
        _writeHandlerBlockQueues = [[NSMutableDictionary alloc] init];
        _stateChangeHandlerBlockQueues = [[NSMutableDictionary alloc] init];
        _pendingOperationPerCharacteristicUUID = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (CBCharacteristic *)characteristicFromUUID:(CBUUID *)characteristicUUID {
    return self.characteristicByUUID[characteristicUUID];
}

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs {
    DDLogDebug(@"Discovering characteristics with UUIDs %@ for service %@", characteristicUUIDs, self.service.UUID.UUIDString);
    [self.peripheral discoverCharacteristics:characteristicUUIDs forService:self.service];
}

- (void)discoverCharacteristics {
    [self discoverCharacteristics:nil];
}

#pragma mark - Reading & writing characteristic value

- (void)readValueForCharacteristicUUID:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    DDLogVerbose(@"Trying to read value for characteristic %@", characteristicUUID.UUIDString);
    __block typeof(self) this = self;
    [self executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (error) {
            block(error, nil);
        } else {
            [this putBlock:block forCharacteristic:characteristicUUID inDictionary:this.readHandlerBlockQueues];
            DDLogDebug(@"Reading value for characteristic %@", characteristicUUID.UUIDString);
            [this.peripheral readValueForCharacteristic:characteristic];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)writeValue:(NSData *)data forCharacteristicUUID:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    DDLogVerbose(@"Trying to write value for characteristic %@", characteristicUUID.UUIDString);
    __block typeof(self) this = self;
    [self executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (error) {
            block(error);
        } else {
            [this putBlock:block forCharacteristic:characteristicUUID inDictionary:this.writeHandlerBlockQueues];
            DDLogDebug(@"Writting value for characteristic %@ with response", characteristicUUID);
            [this.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)writeValue:(NSData *)data forCharacteristicUUID:(CBUUID *)characteristicUUID {
    WLXAssertNotNil(characteristicUUID);
    __block typeof(self) this = self;
    DDLogVerbose(@"Trying to write value for characteristic %@", characteristicUUID.UUIDString);
    [self executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (!error) {
            DDLogDebug(@"Writting value for characteristic %@ without response", characteristicUUID);
            [this.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        }
    } forCharacteristic:characteristicUUID];
}

#pragma mark - Handling characteristic notifications

- (void)enableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    [self setNotification:YES forCharacteristic:characteristicUUID usingBlock:block];
}

- (void)disableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    [self setNotification:NO forCharacteristic:characteristicUUID usingBlock:block];
}

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    DDLogVerbose(@"Adding observer for characteristic %@", characteristicUUID);
    // Dispatching the block to a separate queue relives the main bluetooth queue for any delay that might occur
    // while processing characteristic update notifications.
    id dispatchedBlock = ^(NSError * error, NSData * data) {
        dispatch_async(_queue, ^{ block(error, data); });
    };
    return [self putBlock:dispatchedBlock forCharacteristic:characteristicUUID inDictionary:self.observers];
}

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID selector:(SEL)selector target:(id)target {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(selector);
    WLXAssertNotNil(target);
    return [self addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
        // This is done this way to avoid a compiler warning!
        // All the selector should return void and accept an error and a data object.
        // http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknow
        IMP imp = [target methodForSelector:selector];
        void (*func)(id, SEL, NSError *, NSData *) = (void *)imp;
        func(target, selector, error, data);
    }];
}

- (void)removeObserver:(id)observer {
    DDLogVerbose(@"Removing observer %p.", observer);
    for (NSMutableArray * observers in self.observers) {
        if ([observers containsObject:observer]) {
            [observers removeObject:observer];
            DDLogVerbose(@"Observer %p successfully removed.", observer);
            break;
        }
    }
}

#pragma mark - WLXServicesManagerDelegate methods

- (void)didDiscoverCharacteristics {
    DDLogDebug(@"Characterisctics successfully discovered %@", self.characteristics);
    [self cacheDiscoveredCharacteristics];
    [self flushPendingOperations];
}

- (void)failToDiscoverCharacteristics:(NSError *)error {
    WLXAssertNotNil(error);
    DDLogDebug(@"Characteristics could not be discovered: %@", error);
    [self flushPendingOperationsWithError:error];
}

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    WLXAssertNotNil(characteristic);
    if (error) {
        DDLogVerbose(@"Value for characteristic %@ could not be updated: %@", characteristic.UUID.UUIDString, error);
    } else {
        DDLogVerbose(@"Value for characteristic %@ has been updated", characteristic.UUID.UUIDString);
    }
    NSMutableArray * blocks = self.readHandlerBlockQueues[characteristic.UUID];
    void (^block)(NSError *, NSData *) = [blocks firstObject];
    NSData * data = (error) ? nil : characteristic.value;
    if (block) {
        DDLogVerbose(@"Dispatching value for characteristic %@ to registered block", characteristic.UUID.UUIDString);
        block(error, data);
        [blocks removeObject:block];
    } else {
        DDLogVerbose(@"Dispatching value for characteristic %@ to observers", characteristic.UUID.UUIDString);
        for (void(^observer)(NSError *, NSData *) in self.observers[characteristic.UUID]) {
            observer(error, data);
        }
    }
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    WLXAssertNotNil(characteristic);
    if (error) {
        DDLogVerbose(@"Value for characteristic %@ could not be written: %@", characteristic.UUID.UUIDString, error);
    } else {
        DDLogVerbose(@"Value for characteristic %@ has been written", characteristic.UUID.UUIDString);
    }
    NSMutableArray * blocks = self.writeHandlerBlockQueues[characteristic.UUID];
    void (^block)(NSError *) = [blocks firstObject];
    if (block) {
        block(error);
        [blocks removeObject:block];
    } else {
        DDLogWarn(@"Write success notification for characteristic %@ could not be dispatched. There is no registered block",
                  characteristic.UUID.UUIDString);
    }
}

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    WLXAssertNotNil(characteristic);
    if (error) {
        DDLogVerbose(@"Notification state for characteristic %@ could not be updated: %@", characteristic.UUID.UUIDString, error);
    } else {
        DDLogVerbose(@"Notification state for characteristic %@ has been updated", characteristic.UUID.UUIDString);
    }
    NSMutableArray * blocks = self.stateChangeHandlerBlockQueues[characteristic.UUID];
    void (^block)(NSError *) = [blocks firstObject];
    if (block) {
        block(error);
        [blocks removeObject:block];
    } else {
        DDLogWarn(@"Notification state change for characteristic %@ could not be dispatched. There is no registered block",
                  characteristic.UUID.UUIDString);
    }
}

#pragma mark - Private methods

- (void)setNotification:(BOOL)enabled forCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    __block typeof(self) this = self;
    DDLogVerbose(@"Trying to set notification state for characteristic %@ to %@", characteristicUUID.UUIDString, (enabled) ? @"YES" : @"NO");
    [self executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (error) {
            block(error);
        } else {
            [this putBlock:block forCharacteristic:characteristicUUID inDictionary:this.stateChangeHandlerBlockQueues];
            DDLogDebug(@"Setting notification state for characteristic %@ to %@", characteristicUUID.UUIDString, (enabled) ? @"YES" : @"NO");
            [this.peripheral setNotifyValue:enabled forCharacteristic:characteristic];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)executeBlock:(void(^)(NSError *, CBCharacteristic *))block forCharacteristic:(CBUUID *)characteristicUUID {
    CBCharacteristic * characteristic = self.characteristicByUUID[characteristicUUID];
    // Dispatching the block to a separate queue relives the main bluetooth queue for any delay that might occur
    // while processing characteristic read or write notifications.
    void(^dispatchedBlock)(NSError *, CBCharacteristic *) = ^(NSError * error, CBCharacteristic * characteristic) {
        dispatch_async(_queue, ^{ block(error, characteristic); });
    };
    if (characteristic) {
        dispatchedBlock(nil, characteristic);
    } else {
        DDLogDebug(@"Characteristic %@ has not been discovered.", characteristicUUID.UUIDString);
        [self executeBlock:dispatchedBlock whenCharacteristicIsDiscovered:characteristicUUID];
    }
}

- (void)executeBlock:(void(^)(NSError *, CBCharacteristic *))block whenCharacteristicIsDiscovered:(CBUUID *)characteristicUUID {
    // Checking if there are pending operations MUST be done before putting the given block
    // to the pending operation queue.
    BOOL pendingOperations = [self pendingOperationsForCharacteristic:characteristicUUID];
    DDLogDebug(@"Enqueuing block to be executed when characteristic %@ gets discovered", characteristicUUID.UUIDString);
    [self putBlock:block forCharacteristic:characteristicUUID inDictionary:self.pendingOperationPerCharacteristicUUID];
    if (!pendingOperations) {
        [self discoverCharacteristics:@[characteristicUUID]];
    } else {
        DDLogDebug(@"There are pending operation for characteristic %@, this mean that discovery for this characteristic has already been started",
                   characteristicUUID.UUIDString);
    }
}

- (void)flushPendingOperations {
    for (CBCharacteristic * characteristic in self.service.characteristics) {
        DDLogDebug(@"Flusing pending operations for characteristic %@", characteristic.UUID.UUIDString);
        NSMutableArray * operations = self.pendingOperationPerCharacteristicUUID[characteristic.UUID];
        for (void(^operation)(NSError *, CBCharacteristic *) in operations) {
            operation(nil, characteristic);
        }
        [operations removeAllObjects];
    }
}

- (void)flushPendingOperationsWithError:(NSError *)error {
    for (CBUUID * characteristicUUID in [self.pendingOperationPerCharacteristicUUID allKeys]) {
        DDLogDebug(@"Flusing pending operations with error for characteristic %@", characteristicUUID.UUIDString);
        NSMutableArray * operations = self.pendingOperationPerCharacteristicUUID[characteristicUUID];
        for (void(^operation)(NSError *, CBCharacteristic *) in operations) {
            operation(error, nil);
        }
        [operations removeAllObjects];
    }
}

- (BOOL)pendingOperationsForCharacteristic:(CBUUID *)characteristicUUID {
    NSArray * pendingOperations = self.pendingOperationPerCharacteristicUUID[characteristicUUID];
    return pendingOperations != nil && [pendingOperations count] > 0;
}

- (void)cacheDiscoveredCharacteristics {
    for (CBCharacteristic * characteristic in self.service.characteristics) {
        DDLogDebug(@"Caching characteristic %@", characteristic.UUID.UUIDString);
        self.characteristicByUUID[characteristic.UUID] = characteristic;
    }
}

- (id)putBlock:(id)block forCharacteristic:(CBUUID *)characteristicUUID inDictionary:(NSMutableDictionary *)dictionary {
    NSMutableArray * observers = dictionary[characteristicUUID];
    if (observers == nil) {
        observers = dictionary[characteristicUUID] = [[NSMutableArray alloc] init];
    }
    id observer = [block copy];
    [observers addObject:observer];
    return observer;
}

@end
