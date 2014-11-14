//
//  WLXMockService.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 11/12/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import "WLXDummyService.h"

static NSString * serviceUUIDString = @"68753A44-4D6F-1226-9C60-0050E4C00066";
static CBUUID * serviceUUID;

static NSString * characteristicUUIDString = @"68753A44-4D6F-1226-9C60-0050E4C00067";
static CBUUID * characteristicUUID;

@interface  WLXDummyService ()

@property (nonatomic) WLXServiceManager * serviceManager;

@end

@implementation WLXDummyService

+ (void)initialize {
    serviceUUID = [CBUUID UUIDWithString:serviceUUIDString];
    characteristicUUID = [CBUUID UUIDWithString:characteristicUUIDString];
}

+ (CBUUID *)serviceUUID {
    return serviceUUID;
}

- (instancetype)initWithServiceManager:(WLXServiceManager *)serviceManager {
    self = [super init];
    if (self) {
        _serviceManager = serviceManager;
    }
    return self;
}

- (void)readValueUsingBlock:(void(^)(NSError *, NSUInteger))block {
    [self.serviceManager readValueForCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
        if (error) {
            block(error, 0);
        } else {
            if (data.bytes == nil) {
                NSLog(@"The characteristic is empty. Discarding read");
                return;
            }
            NSUInteger value = *((NSUInteger *)data.bytes);
            block(nil, value);
        }
    }];
}

- (void)writeValue:(NSUInteger)value usingBlock:(void(^)(NSError *))block {
    NSData * data = [NSData dataWithBytes:&value length:sizeof(value)];
    [self.serviceManager writeValue:data forCharacteristicUUID:characteristicUUID usingBlock:block];
}

- (void)enableNotificationsUsingBlock:(void(^)(NSError *))block {
    [self.serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:block];
}

- (void)disableNotificationsUsingBlock:(void(^)(NSError *))block {
    [self.serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:block];
}

- (id)addObserverUsingBlock:(void(^)(NSError *, NSUInteger ))block {
    return [self.serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
        if (error) {
            block(error, 0);
        } else {
            block(nil, *((NSUInteger *)data.bytes));
        }
    }];
}

- (void)removeObserver:(id)observer {
    [self.serviceManager removeObserver:observer];
}

@end
