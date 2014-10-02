//
//  WLXBluetoothDeviceManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXBluetoothDeviceRepository.h"

@import CoreBluetooth;

@interface WLXBluetoothDeviceManager : NSObject

@property (nonatomic, readonly) CBCentralManager * centralManager;
@property (nonatomic) NSUInteger maxReconnectionAttempts;
@property (getter=isDiscovering, readonly) BOOL discovering;
@property (getter=isConnected, readonly) BOOL connected;
@property (nonatomic, readonly) CBPeripheral * connectedPeripheral;
@property (nonatomic, readonly) CBPeripheral * lastConnectedPeripheral;
@property (nonatomic, readonly) WLXBluetoothDeviceConnectionRecord * lastConnectionRecord;

+ (instancetype)deviceManager;

+ (instancetype)deviceManagerWithQueue:(dispatch_queue_t)queue;

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                          repository:(id<WLXBluetoothDeviceRepository>)repository
                                 queue:(dispatch_queue_t)queue;

#pragma mark - Discovery management

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex withServices:(NSArray *)servicesUUIDs andTimeout:(NSUInteger)timeout;

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex andTimeout:(NSUInteger)timeout;

- (BOOL)discoverDevicesWithTimeout:(NSUInteger)timeout;

- (void)stopDiscoveringDevices;

#pragma mark - Connection management

- (BOOL)connectWithPeripheral:(CBPeripheral *)peripheral timeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block;

- (BOOL)connectWithPeripheral:(CBPeripheral *)peripheral timeout:(NSUInteger)timeout;

- (BOOL)connectWithPeripheral:(CBPeripheral *)peripheral;

- (BOOL)connectWithLastDeviceWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block;

- (BOOL)connectWithLastDeviceWithTimeout:(NSUInteger)timeout;

- (BOOL)connectWithLastDevice;

- (void)disconnect;


@end
