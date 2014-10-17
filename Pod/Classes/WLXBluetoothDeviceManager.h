//
//  WLXBluetoothDeviceManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXDeviceDiscoverer.h"
#import "WLXConnectionManager.h"
#import "WLXReconnectionStrategy.h"
#import "WLXBluetoothDeviceRegistry.h"

@import CoreBluetooth;

@interface WLXBluetoothDeviceManager : NSObject

@property (nonatomic, readonly) CBCentralManager * centralManager;
@property (nonatomic) id<WLXDeviceDiscoverer> discoverer;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, readonly, getter=isBluetoothOn) BOOL bluetoothOn;

+ (instancetype)deviceManager;

+ (instancetype)deviceManagerWithQueue:(dispatch_queue_t)queue;

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                                 queue:(dispatch_queue_t)queue;


- (id<WLXConnectionManager>)connectionManagerForPeripheral:(CBPeripheral *)peripheral
                                 usingReconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy;


- (WLXBluetoothDeviceRegistry *)deviceRegistryWithRepository:(id<WLXBluetoothDeviceRepository>)repository;

@end
