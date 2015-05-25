//
//  WLXCentralManagerDelegate.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/2/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXBluetoothConnectionManager.h"
#import "WLXBluetoothDeviceDiscoverer.h"

@import CoreBluetooth;

@interface WLXCentralManagerDelegate : NSObject<CBCentralManagerDelegate>

@property (nonatomic) BOOL bluetoothOn;
@property (nonatomic, readonly) WLXBluetoothDeviceDiscoverer * discoverer;

- (instancetype)initWithDiscoverer:(WLXBluetoothDeviceDiscoverer *)discoverer
                notificationCenter:(NSNotificationCenter *)notificationCenter;

- (void)registerConnectionManager:(WLXBluetoothConnectionManager *)connectionManager;

- (void)unregisterConnectionManager:(WLXBluetoothConnectionManager *)connectionManager;

@end
