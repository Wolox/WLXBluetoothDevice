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
#import "WLXDictionaryOfArrays.h"

#define DISPATCH(line)  \
    dispatch_async(_queue, ^{ line; })


static NSString * createQueueName(CBService * service) {
    return [NSString stringWithFormat:@"ar.com.wolox.WLXBluetoothDevice.WLXServiceManager.%@",
            service.UUID.UUIDString];
}

@interface WLXServiceManager ()

@property (nonatomic) CBPeripheral * peripheral;
@property (nonatomic) CBService * service;
@property (nonatomic) NSMutableDictionary * characteristicByUUID;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) NSString * queueName;
@property (nonatomic) WLXDictionaryOfArrays * observers;
@property (nonatomic) WLXDictionaryOfArrays * readHandlerBlockQueues;
@property (nonatomic) WLXDictionaryOfArrays * writeHandlerBlockQueues;
@property (nonatomic) WLXDictionaryOfArrays * stateChangeHandlerBlockQueues;

@end

@implementation WLXServiceManager

@dynamic characteristics;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral service:(CBService *)service {
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(service);
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _service = service;
        _characteristicByUUID = [[NSMutableDictionary alloc] init];
        _observers = [[WLXDictionaryOfArrays alloc] init];
        _queueName = createQueueName(service);
        _queue = dispatch_queue_create([_queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        _readHandlerBlockQueues = [[WLXDictionaryOfArrays alloc] init];
        _writeHandlerBlockQueues = [[WLXDictionaryOfArrays alloc] init];
        _stateChangeHandlerBlockQueues = [[WLXDictionaryOfArrays alloc] init];
        _asyncExecutor = [[WLXCharacteristicAsyncExecutor alloc] initWithCharacteristicLocator:self queue:self.queue];
    }
    return self;
}

- (NSArray *)characteristics {
    return (self.service.characteristics) ? self.service.characteristics : @[];
}

#pragma mark - Reading & writing characteristic value

- (void)readValueFromCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    DDLogVerbose(@"Trying to read value for characteristic %@", characteristicUUID.UUIDString);
    __block typeof(self) this = self;
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (error) {
            DISPATCH(block(error, nil));
        } else {
            this.readHandlerBlockQueues[characteristicUUID] = [block copy];
            DDLogDebug(@"Reading value for characteristic %@", characteristicUUID.UUIDString);
            [this.peripheral readValueForCharacteristic:characteristic];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    WLXAssertNotNil(data);
    DDLogVerbose(@"Trying to write value for characteristic %@", characteristicUUID.UUIDString);
    __block typeof(self) this = self;
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (error) {
            DISPATCH(block(error));
        } else {
            this.writeHandlerBlockQueues[characteristicUUID] = [block copy];
            DDLogDebug(@"Writting value for characteristic %@ with response", characteristicUUID);
            [this.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(data);
    __block typeof(self) this = self;
    DDLogVerbose(@"Trying to write value for characteristic %@", characteristicUUID.UUIDString);
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
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
    return self.observers[characteristicUUID] = [block copy];
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
        void (*func)(id, SEL, NSData *, NSError *) = (void *)imp;
        func(target, selector, data, error);
    }];
}

- (void)removeObserver:(id)observer {
    DDLogVerbose(@"Removing observer %p.", observer);
    for (CBUUID * characteristicUUID in [self.observers allKeys]) {
        NSMutableArray * observers = self.observers[characteristicUUID];
        if ([observers containsObject:observer]) {
            [observers removeObject:observer];
            DDLogVerbose(@"Observer %p successfully removed.", observer);
            break;
        }
    }
}

#pragma mark - WLXCharacteristicLocator methods

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


#pragma mark - WLXServicesManagerDelegate methods

- (void)didDiscoverCharacteristics {
    DDLogDebug(@"Characterisctics successfully discovered %@", self.characteristics);
    [self cacheDiscoveredCharacteristics];
    [self.asyncExecutor flushPendingOperations];
}

- (void)failToDiscoverCharacteristics:(NSError *)error {
    WLXAssertNotNil(error);
    DDLogDebug(@"Characteristics could not be discovered: %@", error);
    [self.asyncExecutor flushPendingOperationsWithError:error];
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
        DISPATCH(block(error, data));
        [blocks removeObject:block];
    } else {
        DDLogVerbose(@"Dispatching value for characteristic %@ to observers", characteristic.UUID.UUIDString);
        for (void(^observer)(NSError *, NSData *) in self.observers[characteristic.UUID]) {
            DISPATCH(observer(error, data));
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
        DISPATCH(block(error));
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
        DISPATCH(block(error));
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
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        if (error) {
            DISPATCH(block(error));
        } else {
            this.stateChangeHandlerBlockQueues[characteristicUUID] = [block copy];
            DDLogDebug(@"Setting notification state for characteristic %@ to %@", characteristicUUID.UUIDString, (enabled) ? @"YES" : @"NO");
            [this.peripheral setNotifyValue:enabled forCharacteristic:characteristic];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)cacheDiscoveredCharacteristics {
    for (CBCharacteristic * characteristic in self.service.characteristics) {
        DDLogDebug(@"Caching characteristic %@", characteristic.UUID.UUIDString);
        self.characteristicByUUID[characteristic.UUID] = characteristic;
    }
}

@end
