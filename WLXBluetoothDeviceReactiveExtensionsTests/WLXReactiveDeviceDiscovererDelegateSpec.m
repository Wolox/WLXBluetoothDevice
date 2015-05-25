//
//  WLXReactiveDeviceDiscovererDelegateSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 3/10/15.
//  Copyright (c) 2015 Guido Marucci Blas. All rights reserved.
//
#import "SpecHelper.h"

SpecBegin(WLXReactiveDeviceDiscovererDelegate)

__block WLXReactiveDeviceDiscovererDelegate * delegate;
__block id<WLXDeviceDiscoverer> discoverer;

beforeEach(^{
    delegate = [[WLXReactiveDeviceDiscovererDelegate alloc] init];
});

describe(@"#startDiscoveringDevices", ^{
    
    __block NSUInteger timeout;
    
    beforeEach(^{
        timeout = 10;
        discoverer = mockProtocol(@protocol(WLXDeviceDiscoverer));
    });
    
    context(@"when the device discoverer starts discovering devices", ^{
       
        it(@"sends the timeout use to discover devices", ^{
            [delegate.startDiscoveringDevices subscribeNext:^(NSNumber * aTimeout) {
                expect(aTimeout.unsignedIntegerValue).to.equal(timeout);
            }];
            [delegate deviceDiscoverer:discoverer startDiscoveringDevicesWithTimeout:timeout];
        });
        
    });
    
});

describe(@"#stopDiscoveringDevices", ^{
   
    context(@"when the device discoverer stops discovering devices", ^{
       
        it(@"sends a RACUnit", ^{ waitUntil(^(DoneCallback done) {
            [delegate.stopDiscoveringDevices subscribeNext:^(id x) {
                done();
            }];
            [delegate deviceDiscovererStopDiscoveringDevices:discoverer];
        });});
        
    });
    
});

describe(@"#discoveredDevice", ^{
   
    context(@"when the device discoverer discovers a new device", ^{
        
        __block WLXDeviceDiscoveryData * discoveryData;
        
        beforeEach(^{
            discoveryData = mock([WLXDeviceDiscoveryData class]);
        });
        
        it(@"sends the discovery data object", ^{
            [delegate.discoveredDevice subscribeNext:^(WLXDeviceDiscoveryData * aDiscoveryData) {
                expect(aDiscoveryData).to.equal(discoveryData);
            }];
            [delegate deviceDiscoverer:discoverer discoveredDevice:discoveryData];
        });
        
    });
    
});

SpecEnd
