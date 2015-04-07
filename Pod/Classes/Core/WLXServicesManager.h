//
//  WLXServiceManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXServiceManager.h"

extern NSString * const WLXBluetoothDeviceServiceErrorDomain;
typedef enum : NSUInteger {
    WLXBluetoothDeviceServiceErrorServicesDiscoveryAlreadyStarted,
} WLXBluetoothDeviceServiceError;

@import CoreBluetooth;

@interface WLXServicesManager : NSObject<CBPeripheralDelegate>

@property (nonatomic, readonly) NSArray * services;
@property (nonatomic, readonly) BOOL discovering;
@property (nonatomic, readonly) BOOL servicesDiscovered;
@property (nonatomic, readonly) BOOL invalidated;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral notificationCenter:(NSNotificationCenter *)notificationCenter;

- (BOOL)discoverServicesUsingBlock:(void(^)(NSError *))block;

- (CBService *)serviceFromUUID:(CBUUID *)serviceUUID;

- (WLXServiceManager *)managerForService:(CBUUID *)serviceUUID;

@end
