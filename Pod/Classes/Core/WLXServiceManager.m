//
//  WLXServiceManager.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import "WLXServiceManager.h"

#import "WLXBluetoothDeviceNotifications.h"
#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceLogger.h"
#import "WLXDictionaryOfArrays.h"

#define DISPATCH(line)  \
    dispatch_async(_queue, ^{ line; })

#define ASSERT_IF_VALID NSAssert(self.invalidated == NO, @"The service manager has been invalidated. Obtain a new service manager from the WLXServicesManager#managerForService: method")



static NSString * createQueueName(CBService * service) {
    return [NSString stringWithFormat:@"ar.com.wolox.WLXBluetoothDevice.WLXServiceManager.%@",
            service.UUID.UUIDString];
}

@interface WLXServiceManager ()

@property (nonatomic) NSNotificationCenter * notificationCenter;
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

DYNAMIC_LOGGER_METHODS

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                           service:(CBService *)service
                notificationCenter:(NSNotificationCenter *)notificationCenter {
    WLXAssertNotNil(peripheral);
    WLXAssertNotNil(service);
    WLXAssertNotNil(notificationCenter);
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _service = service;
        _notificationCenter = notificationCenter;
        _characteristicByUUID = [[NSMutableDictionary alloc] init];
        _observers = [[WLXDictionaryOfArrays alloc] init];
        _queueName = createQueueName(service);
        _queue = dispatch_queue_create([_queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        _readHandlerBlockQueues = [[WLXDictionaryOfArrays alloc] init];
        _writeHandlerBlockQueues = [[WLXDictionaryOfArrays alloc] init];
        _stateChangeHandlerBlockQueues = [[WLXDictionaryOfArrays alloc] init];
        _asyncExecutor = [[WLXCharacteristicAsyncExecutor alloc] initWithCharacteristicLocator:self queue:self.queue];
        _invalidated = NO;
        [self invalidateServiceManagerOnConnectionLost];
    }
    return self;
}

- (void)dealloc {
    [self removeInvalidateServiceManagerObservers];
}

- (NSArray *)characteristics {
    return (self.service.characteristics) ? self.service.characteristics : @[];
}

#pragma mark - Reading & writing characteristic value

- (void)readValueFromCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block {
    ASSERT_IF_VALID;
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    WLXLogVerbose(@"Trying to read value for characteristic %@", characteristicUUID.UUIDString);
    __weak typeof(self) wself = self;
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        __strong typeof(self) this = wself;
        if (error) {
            DISPATCH(block(error, nil));
        } else {
            this.readHandlerBlockQueues[characteristicUUID] = [block copy];
            WLXLogDebug(@"Reading value for characteristic %@", characteristicUUID.UUIDString);
            [this.peripheral readValueForCharacteristic:characteristic];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    ASSERT_IF_VALID;
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    WLXAssertNotNil(data);
    WLXLogVerbose(@"Trying to write value for characteristic %@", characteristicUUID.UUIDString);
    __weak typeof(self) wself = self;
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        __strong typeof(self) this = wself;
        if (error) {
            DISPATCH(block(error));
        } else {
            this.writeHandlerBlockQueues[characteristicUUID] = [block copy];
            WLXLogDebug(@"Writting value for characteristic %@ with response", characteristicUUID);
            [this.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID {
    ASSERT_IF_VALID;
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(data);
    __weak typeof(self) wself = self;
    WLXLogVerbose(@"Trying to write value for characteristic %@", characteristicUUID.UUIDString);
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        __strong typeof(self) this = wself;
        if (!error) {
            WLXLogDebug(@"Writting value for characteristic %@ without response", characteristicUUID);
            [this.peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        }
    } forCharacteristic:characteristicUUID];
}

#pragma mark - Handling characteristic notifications

- (void)enableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    ASSERT_IF_VALID;
    [self setNotification:YES forCharacteristic:characteristicUUID usingBlock:block];
}

- (void)disableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    ASSERT_IF_VALID;
    [self setNotification:NO forCharacteristic:characteristicUUID usingBlock:block];
}

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block {
    ASSERT_IF_VALID;
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    WLXLogVerbose(@"Adding observer for characteristic %@", characteristicUUID);
    return self.observers[characteristicUUID] = [block copy];
}

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID selector:(SEL)selector target:(id)target {
    ASSERT_IF_VALID;
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
    if (self.invalidated) {
        WLXLogVerbose(@"Service manager for service '%@' is invalidated. Call to removeObserver ignored.", self.serviceUUID);
        return;
    }
    
    WLXLogVerbose(@"Removing observer %p.", observer);
    for (CBUUID * characteristicUUID in [self.observers allKeys]) {
        NSMutableArray * observers = self.observers[characteristicUUID];
        if ([observers containsObject:observer]) {
            [observers removeObject:observer];
            WLXLogVerbose(@"Observer %p successfully removed.", observer);
            break;
        }
    }
}

#pragma mark - WLXCharacteristicLocator methods

- (CBCharacteristic *)characteristicFromUUID:(CBUUID *)characteristicUUID {
    ASSERT_IF_VALID;
    return self.characteristicByUUID[characteristicUUID];
}

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs {
    ASSERT_IF_VALID;
    NSAssert(self.invalidated == NO, @"The service manager has been invalidated. Obtain a new service manager from the WLXServicesManager#managerForService: method");
    WLXLogDebug(@"Discovering characteristics with UUIDs %@ for service %@", characteristicUUIDs, self.service.UUID.UUIDString);
    [self.peripheral discoverCharacteristics:characteristicUUIDs forService:self.service];
}

- (void)discoverCharacteristics {
    ASSERT_IF_VALID;
    [self discoverCharacteristics:nil];
}


#pragma mark - WLXServicesManagerDelegate methods

- (void)didDiscoverCharacteristics {
    WLXLogDebug(@"Characterisctics successfully discovered %@", self.characteristics);
    [self cacheDiscoveredCharacteristics];
    [self.asyncExecutor flushPendingOperations];
}

- (void)failToDiscoverCharacteristics:(NSError *)error {
    WLXAssertNotNil(error);
    WLXLogDebug(@"Characteristics could not be discovered: %@", error);
    [self.asyncExecutor flushPendingOperationsWithError:error];
}

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    WLXAssertNotNil(characteristic);
    if (error) {
        WLXLogVerbose(@"Value for characteristic %@ could not be updated: %@", characteristic.UUID.UUIDString, error);
    } else {
        WLXLogVerbose(@"Value for characteristic %@ has been updated", characteristic.UUID.UUIDString);
    }
    NSMutableArray * blocks = self.readHandlerBlockQueues[characteristic.UUID];
    void (^block)(NSError *, NSData *) = [blocks firstObject];
    NSData * data = (error) ? nil : characteristic.value;
    if (block) {
        WLXLogVerbose(@"Dispatching value for characteristic %@ to registered block", characteristic.UUID.UUIDString);
        DISPATCH(block(error, data));
        [blocks removeObject:block];
    } else {
        WLXLogVerbose(@"Dispatching value for characteristic %@ to observers", characteristic.UUID.UUIDString);
        for (void(^observer)(NSError *, NSData *) in self.observers[characteristic.UUID]) {
            DISPATCH(observer(error, data));
        }
    }
}

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    WLXAssertNotNil(characteristic);
    if (error) {
        WLXLogVerbose(@"Value for characteristic %@ could not be written: %@", characteristic.UUID.UUIDString, error);
    } else {
        WLXLogVerbose(@"Value for characteristic %@ has been written", characteristic.UUID.UUIDString);
    }
    NSMutableArray * blocks = self.writeHandlerBlockQueues[characteristic.UUID];
    void (^block)(NSError *) = [blocks firstObject];
    if (block) {
        DISPATCH(block(error));
        [blocks removeObject:block];
    } else {
        WLXLogWarn(@"Write success notification for characteristic %@ could not be dispatched. There is no registered block",
                  characteristic.UUID.UUIDString);
    }
}

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    WLXAssertNotNil(characteristic);
    if (error) {
        WLXLogVerbose(@"Notification state for characteristic %@ could not be updated: %@", characteristic.UUID.UUIDString, error);
    } else {
        WLXLogVerbose(@"Notification state for characteristic %@ has been updated", characteristic.UUID.UUIDString);
    }
    NSMutableArray * blocks = self.stateChangeHandlerBlockQueues[characteristic.UUID];
    void (^block)(NSError *) = [blocks firstObject];
    if (block) {
        DISPATCH(block(error));
        [blocks removeObject:block];
    } else {
        WLXLogWarn(@"Notification state change for characteristic %@ could not be dispatched. There is no registered block",
                  characteristic.UUID.UUIDString);
    }
}

#pragma mark - Private methods

- (void)invalidateServiceManagerOnConnectionLost {
    [self invalidateServiceManagerOnNotification:WLXBluetoothDeviceConnectionLost];
    [self invalidateServiceManagerOnNotification:WLXBluetoothDeviceReconnecting];
    [self invalidateServiceManagerOnNotification:WLXBluetoothDeviceConnectionTerminated];
}

- (void)invalidateServiceManagerOnNotification:(NSString *)notificationName {
    [self.notificationCenter addObserver:self
                                selector:@selector(invalidateServiceManager:)
                                    name:notificationName
                                  object:nil];
}

- (void)removeInvalidateServiceManagerObservers {
    [self.notificationCenter removeObserver:self name:WLXBluetoothDeviceConnectionTerminated object:nil];
    [self.notificationCenter removeObserver:self name:WLXBluetoothDeviceConnectionLost object:nil];
    [self.notificationCenter removeObserver:self name:WLXBluetoothDeviceReconnecting object:nil];
}

- (NSString *)serviceUUID {
    return self.service.UUID.UUIDString;
}

- (void)invalidateServiceManager:(NSNotification *)notifiation {
    WLXLogDebug(@"Service manager for service '%@' has been invalidated", self.serviceUUID);
    _invalidated = YES;
    [self removeInvalidateServiceManagerObservers];
}

- (void)setNotification:(BOOL)enabled forCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block {
    WLXAssertNotNil(characteristicUUID);
    WLXAssertNotNil(block);
    __weak typeof(self) wself = self;
    WLXLogVerbose(@"Trying to set notification state for characteristic %@ to %@", characteristicUUID.UUIDString, (enabled) ? @"YES" : @"NO");
    [self.asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
        __strong typeof(self) this = wself;
        if (error) {
            DISPATCH(block(error));
        } else {
            this.stateChangeHandlerBlockQueues[characteristicUUID] = [block copy];
            WLXLogDebug(@"Setting notification state for characteristic %@ to %@", characteristicUUID.UUIDString, (enabled) ? @"YES" : @"NO");
            [this.peripheral setNotifyValue:enabled forCharacteristic:characteristic];
        }
    } forCharacteristic:characteristicUUID];
}

- (void)cacheDiscoveredCharacteristics {
    for (CBCharacteristic * characteristic in self.service.characteristics) {
        WLXLogDebug(@"Caching characteristic %@", characteristic.UUID.UUIDString);
        self.characteristicByUUID[characteristic.UUID] = characteristic;
    }
}

@end
