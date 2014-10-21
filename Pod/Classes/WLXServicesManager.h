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

@interface WLXServicesManager : NSObject

@property (nonatomic, readonly) NSArray * services;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral;

- (BOOL)discoverServicesUsingBlock:(void(^)(NSError *))block;

- (BOOL)discoverServices;

- (CBService *)serviceFromUUID:(CBUUID *)serviceUUID;

- (WLXServiceManager *)managerForService:(CBUUID *)serviceUUID;

@end
