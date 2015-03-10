//
//  WLXReactiveDeviceDiscovererDelegate.h
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import <Foundation/Foundation.h>
#import "WLXDeviceDiscovererDelegate.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface WLXReactiveDeviceDiscovererDelegate : NSObject<WLXDeviceDiscovererDelegate>

@property (nonatomic, readonly) RACSignal * startDiscoveringDevices;
@property (nonatomic, readonly) RACSignal * stopDiscoveringDevices;
@property (nonatomic, readonly) RACSignal * discoveredDevice;

@end
