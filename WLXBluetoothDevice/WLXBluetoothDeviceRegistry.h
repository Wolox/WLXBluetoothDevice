//
//  WLXBluetoothDeviceRegistry.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/5/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXBluetoothDeviceRepository.h"

@interface WLXBluetoothDeviceRegistry : NSObject

@property (nonatomic) BOOL enabled;

- (instancetype)initWithRepository:(id<WLXBluetoothDeviceRepository>)repository
                notificationCenter:(NSNotificationCenter * )notificationCenter
                    centralManager:(CBCentralManager *)centralManager;

- (void)fetchLastConnectionRecordWithBlock:(void(^)(NSError *, WLXBluetoothDeviceConnectionRecord *))block;

- (void)fetchLastConnectedPeripheralWithBlock:(void(^)(NSError *, CBPeripheral *))block;


@end
