//
//  WLXServiceManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXServicesManagerDelegate.h"

@import CoreBluetooth;

@interface WLXServiceManager : NSObject<WLXServicesManagerDelegate>

@property (nonatomic, readonly) NSArray * characteristics;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral service:(CBService *)service;

- (CBCharacteristic *)characteristicFromUUID:(CBUUID *)characteristicUUID;

- (void)discoverCharacteristics;

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs;

#pragma mark - Reading & writing characteristic value

- (void)readValueForCharacteristicUUID:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block;

- (void)writeValue:(NSData *)data forCharacteristicUUID:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block;

- (void)writeValue:(NSData *)data forCharacteristicUUID:(CBUUID *)characteristicUUID;

#pragma mark - Handling characteristic notifications

- (void)enableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block;

- (void)disableNotificationsForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *))block;

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID usingBlock:(void(^)(NSError *, NSData *))block;

- (id)addObserverForCharacteristic:(CBUUID *)characteristicUUID selector:(SEL)selector target:(id)target;

- (void)removeObserver:(id)observer;

@end
