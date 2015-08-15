//
//  WLXBluetoothDeviceRegistry.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/5/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXBluetoothDeviceRepository.h"

@interface WLXBluetoothDeviceRegistry : NSObject<WLXBluetoothDeviceRepository>

@property (nonatomic) BOOL enabled;

- (instancetype)initWithRepository:(id<WLXBluetoothDeviceRepository>)repository
                notificationCenter:(NSNotificationCenter * )notificationCenter
                    centralManager:(CBCentralManager *)centralManager;

- (void)fetchLastConnectedPeripheralWithBlock:(void(^)(NSError *, CBPeripheral *))block;

@end
