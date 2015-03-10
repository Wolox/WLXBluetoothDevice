//
//  WLXReactiveDeviceDiscovererDelegate.m
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import "WLXReactiveDeviceDiscovererDelegate.h"

@interface WLXReactiveDeviceDiscovererDelegate ()

@property (nonatomic) RACSubject * startDiscoveringDevicesSubject;
@property (nonatomic) RACSubject * stopDiscoveringDevicesSubject;
@property (nonatomic) RACSubject * discoveredDeviceSubject;

@end

@implementation WLXReactiveDeviceDiscovererDelegate

@dynamic startDiscoveringDevices;
@dynamic stopDiscoveringDevices;
@dynamic discoveredDevice;

- (instancetype)init {
    self = [super init];
    if (self) {
        _startDiscoveringDevicesSubject = [RACSubject subject];
        _stopDiscoveringDevicesSubject = [RACSubject subject];
        _discoveredDeviceSubject = [RACSubject subject];
    }
    return self;
}

- (RACSignal *)startDiscoveringDevices {
    return self.startDiscoveringDevicesSubject;
}

- (RACSignal *)stopDiscoveringDevices {
    return self.stopDiscoveringDevicesSubject;
}

- (RACSignal *)discoveredDevice {
    return self.discoveredDeviceSubject;
}

#pragma mark - WLXDeviceDiscovererDelegate methods

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer startDiscoveringDevicesWithTimeout:(NSUInteger)timeout {
    [self.startDiscoveringDevicesSubject sendNext:@(timeout)];
}

- (void)deviceDiscoverer:(id<WLXDeviceDiscoverer>)discoverer discoveredDevice:(WLXDeviceDiscoveryData *)discoveryData {
    [self.discoveredDeviceSubject sendNext:discoveryData];
}

- (void)deviceDiscovererStopDiscoveringDevices:(id<WLXDeviceDiscoverer>)discoverer {
    [self.stopDiscoveringDevicesSubject sendNext:[RACUnit defaultUnit]];
}

@end
