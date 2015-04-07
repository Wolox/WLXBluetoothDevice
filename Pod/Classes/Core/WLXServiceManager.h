//
//  WLXServiceManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXServicesManagerDelegate.h"
#import "WLXCharacteristicAsyncExecutor.h"
#import "WLXCharacteristicLocator.h"

@import CoreBluetooth;

@interface WLXServiceManager : NSObject<WLXServicesManagerDelegate, WLXCharacteristicLocator>

@property (nonatomic) WLXCharacteristicAsyncExecutor * asyncExecutor;
@property (nonatomic, readonly) NSArray * characteristics;
@property (nonatomic, readonly) BOOL invalidated;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                           service:(CBService *)service
                notificationCenter:(NSNotificationCenter *)notificationCenter;

#pragma mark - Reading & writing characteristic value

- (void)readValueFromCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block;

- (void)writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block;

- (void)writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID;

#pragma mark - Handling characteristic notifications

- (void)enableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block;

- (void)disableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block;

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block;

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID selector:(SEL)selector target:(id)target;

- (void)removeObserver:(id)observer;

@end
