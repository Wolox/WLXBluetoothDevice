//
//  WLXBluetoothDeviceConnectionRecord.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXDateProvider.h"

@import CoreBluetooth;

@interface WLXBluetoothDeviceConnectionRecord : NSObject<NSCoding>

@property (nonatomic, readonly) NSString * UUID;
@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSDate * connectionDate;

+ (void)setDateProvider:(id<WLXDateProvider>)dateProvider;

+ (instancetype)recordWithPeripheral:(CBPeripheral *)peripheral;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral connectionDate:(NSDate *)connectionDate;

- (instancetype)initWithUUID:(NSString *)UUID name:(NSString *)name connectionDate:(NSDate *)connectionDate;


@end
