//
//  WLXMockService.h
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 11/12/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLXDummyService : NSObject

+ (CBUUID *)serviceUUID;

- (instancetype)initWithServiceManager:(WLXServiceManager *)serviceManager;

- (void)readValueUsingBlock:(void(^)(NSError *, NSUInteger))block;

- (void)writeValue:(NSUInteger)value usingBlock:(void(^)(NSError *))block;

- (void)enableNotificationsUsingBlock:(void(^)(NSError *))block;

- (void)disableNotificationsUsingBlock:(void(^)(NSError *))block;

- (id)addObserverUsingBlock:(void(^)(NSError *, NSUInteger ))block;

- (void)removeObserver:(id)observer;

@end
