//
//  WLXDeviceDiscovererDelegate.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/20/14.
//
//

#import <Foundation/Foundation.h>

@protocol WLXDeviceDiscoverer;
@class WLXDeviceDiscoveryData;

@protocol WLXDeviceDiscovererDelegate <NSObject>

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer startDiscoveringDevicesWithTimeout:(NSUInteger)timeout;

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer discoveredDevice:(WLXDeviceDiscoveryData *)discoveryData;

- (void)deviceDiscovererStopDiscoveringDevices:(id<WLXDeviceDiscoverer>)discoverer;

@end
