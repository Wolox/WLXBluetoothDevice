//
//  WLXBluetoohDeviceDiscoverer.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXDeviceDiscoverer.h"
#import "WLXDeviceDiscoveryData.h"
#import "WLXBluetoothDeviceNotifications.h"

@import CoreBluetooth;

@interface WLXBluetoothDeviceDiscoverer : NSObject<WLXDeviceDiscoverer>

@property (getter=isDiscovering) BOOL discovering;
@property (nonatomic, readonly) NSArray * discoveredDevices;
@property (nonatomic) NSDictionary * scanOptions;
@property (nonatomic, weak) id<WLXDeviceDiscovererDelegate> delegate;

- (instancetype)initWithCentralManager:(CBCentralManager *)centralManager
                    notificationCenter:(NSNotificationCenter *)notificationCenter
                                 queue:(dispatch_queue_t)queue;

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex withServices:(NSArray *)servicesUUIDs andTimeout:(NSUInteger)timeout;

- (void)stopDiscoveringDevices;

- (BOOL)addDiscoveredDevice:(WLXDeviceDiscoveryData *)deviceDiscoveryData;

@end
