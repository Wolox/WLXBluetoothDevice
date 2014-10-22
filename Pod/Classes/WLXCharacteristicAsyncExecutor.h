//
//  WLXCharacteristicAsyncExecutor.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/22/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXCharacteristicLocator.h"

@import CoreBluetooth;

@interface WLXCharacteristicAsyncExecutor : NSObject

- (instancetype)initWithCharacteristicLocator:(id<WLXCharacteristicLocator>)locator queue:(dispatch_queue_t)queue;

- (void)executeBlock:(void(^)(NSError *, CBCharacteristic *))block forCharacteristic:(CBUUID *)characteristicUUID;

- (NSUInteger)pendingOperationsCountForCharacteristic:(CBUUID *)characteristicUUID;

- (void)flushPendingOperations;

- (void)flushPendingOperationsWithError:(NSError *)error;

@end
