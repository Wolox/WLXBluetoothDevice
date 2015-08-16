//
//  WLXBluetoothDeviceRepository.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXBluetoothDeviceConnectionRecord.h"

@protocol WLXBluetoothDeviceRepository <NSObject>

- (void)fetchLastConnectionRecordWithBlock:(void(^)(NSError *, WLXBluetoothDeviceConnectionRecord *))block;

- (void)fetchConnectionRecordsWithBlock:(void(^)(NSError *, NSArray *))block;

- (void)deleteConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord withBlock:(void(^)(NSError *))block;

- (void)deleteConnectionRecordWithUUID:(NSString *)UUID andBlock:(void(^)(NSError *))block;

- (void)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord withBlock:(void(^)(NSError *))block;

@end
