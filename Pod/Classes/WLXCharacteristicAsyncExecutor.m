//
//  WLXCharacteristicAsyncExecutor.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/22/14.
//
//

#import "WLXCharacteristicAsyncExecutor.h"

#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceLogger.h"
#import "WLXDictionaryOfArrays.h"

@interface WLXCharacteristicAsyncExecutor ()

@property (nonatomic, readonly) id<WLXCharacteristicLocator> locator;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic) WLXDictionaryOfArrays * pendingOperations;

@end

@implementation WLXCharacteristicAsyncExecutor

DYNAMIC_LOGGER_METHODS

- (instancetype)initWithCharacteristicLocator:(id<WLXCharacteristicLocator>)locator queue:(dispatch_queue_t)queue {
    WLXAssertNotNil(locator);
    self = [super init];
    if (self) {
        _queue = queue;
        _locator = locator;
        _pendingOperations = [[WLXDictionaryOfArrays alloc] init];
    }
    return self;
}

- (void)executeBlock:(void(^)(NSError *, CBCharacteristic *))block forCharacteristic:(CBUUID *)characteristicUUID {
    CBCharacteristic * characteristic = [self.locator characteristicFromUUID:characteristicUUID];
    // Dispatching the block to a separate queue relives the main bluetooth queue for any delay that might occur
    // while processing characteristic read or write notifications.
    void(^dispatchedBlock)(NSError *, CBCharacteristic *) = ^(NSError * error, CBCharacteristic * characteristic) {
        dispatch_async(_queue, ^{ block(error, characteristic); });
    };
    if (characteristic) {
        dispatchedBlock(nil, characteristic);
    } else {
        WLXLogDebug(@"Characteristic %@ has not been discovered.", characteristicUUID.UUIDString);
        [self executeBlock:dispatchedBlock whenCharacteristicIsDiscovered:characteristicUUID];
    }
}

- (NSUInteger)pendingOperationsCountForCharacteristic:(CBUUID *)characteristicUUID {
    return [self.pendingOperations[characteristicUUID] count];
}

- (void)flushPendingOperations {
    for (CBCharacteristic * characteristic in self.locator.characteristics) {
        WLXLogDebug(@"Flusing pending operations for characteristic %@", characteristic.UUID.UUIDString);
        NSMutableArray * operations = self.pendingOperations[characteristic.UUID];
        for (void(^operation)(NSError *, CBCharacteristic *) in operations) {
            operation(nil, characteristic);
        }
        [operations removeAllObjects];
    }
}

- (void)flushPendingOperationsWithError:(NSError *)error {
    for (CBUUID * characteristicUUID in [self.pendingOperations allKeys]) {
        WLXLogDebug(@"Flusing pending operations with error for characteristic %@", characteristicUUID.UUIDString);
        NSMutableArray * operations = self.pendingOperations[characteristicUUID];
        for (void(^operation)(NSError *, CBCharacteristic *) in operations) {
            operation(error, nil);
        }
        [operations removeAllObjects];
    }
}

#pragma mark - Private mehtods

- (void)executeBlock:(void(^)(NSError *, CBCharacteristic *))block whenCharacteristicIsDiscovered:(CBUUID *)characteristicUUID {
    // Checking if there are pending operations MUST be done before putting the given block
    // to the pending operation queue.
    BOOL pendingOperations = [self pendingOperationsForCharacteristic:characteristicUUID];
    WLXLogDebug(@"Enqueuing block to be executed when characteristic %@ gets discovered", characteristicUUID.UUIDString);
    self.pendingOperations[characteristicUUID] = [block copy];
    if (!pendingOperations) {
        [self.locator discoverCharacteristics:@[characteristicUUID]];
    } else {
        WLXLogDebug(@"There are pending operation for characteristic %@, this mean that discovery for this characteristic has already been started",
                   characteristicUUID.UUIDString);
    }
}

- (BOOL)pendingOperationsForCharacteristic:(CBUUID *)characteristicUUID {
    return [self.pendingOperations[characteristicUUID] count] > 0;
}

@end
