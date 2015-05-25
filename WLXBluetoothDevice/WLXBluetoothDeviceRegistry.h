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
@property (nonatomic, readonly) CBPeripheral * lastConnectedPeripheral;
@property (nonatomic, readonly) WLXBluetoothDeviceConnectionRecord * lastConnectionRecord;

- (instancetype)initWithRepository:(id<WLXBluetoothDeviceRepository>)repository
                notificationCenter:(NSNotificationCenter * )notificationCenter
                    centralManager:(CBCentralManager *)centralManager;

@end
