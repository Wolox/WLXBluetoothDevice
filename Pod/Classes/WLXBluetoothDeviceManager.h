//
//  WLXBluetoothDeviceManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXBluetoothDeviceRepository.h"
#import "WLXDeviceDiscoverer.h"
#import "WLXConnectionManager.h"
#import "WLXReconnectionStrategy.h"

@import CoreBluetooth;

@interface WLXBluetoothDeviceManager : NSObject

@property (nonatomic, readonly) CBCentralManager * centralManager;
@property (nonatomic, readonly) CBPeripheral * lastConnectedPeripheral;
@property (nonatomic, readonly) WLXBluetoothDeviceConnectionRecord * lastConnectionRecord;
@property (nonatomic) id<WLXDeviceDiscoverer> discoverer;

+ (instancetype)deviceManager;

+ (instancetype)deviceManagerWithQueue:(dispatch_queue_t)queue;

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                            repository:(id<WLXBluetoothDeviceRepository>)repository
                                 queue:(dispatch_queue_t)queue;


- (id<WLXConnectionManager>)connectionManagerForPeripheral:(CBPeripheral *)peripheral
                                 usingReconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy;


@end
