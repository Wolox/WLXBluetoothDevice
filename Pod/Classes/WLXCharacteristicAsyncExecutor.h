//
//  WLXCharacteristicAsyncExecutor.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/22/14.
//
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@class WLXServiceManager;

@interface WLXCharacteristicAsyncExecutor : NSObject

- (instancetype)initWithServiceManager:(WLXServiceManager *)serviceManager queue:(dispatch_queue_t)queue;

- (void)executeBlock:(void(^)(NSError *, CBCharacteristic *))block forCharacteristic:(CBUUID *)characteristicUUID;

- (void)flushPendingOperations;

- (void)flushPendingOperationsWithError:(NSError *)error;

@end
