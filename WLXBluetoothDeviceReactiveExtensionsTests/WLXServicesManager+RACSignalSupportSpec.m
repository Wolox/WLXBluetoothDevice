//
//  WLXServicesManager+RACSignalSupportSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 3/11/15.
//  Copyright (c) 2015 Guido Marucci Blas. All rights reserved.
//
#import "SpecHelper.h"

SpecBegin(WLXServicesManager_RACSignalSupport)

__block CBPeripheral * peripheral;
__block WLXServicesManager * servicesManager;

beforeEach(^{
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    peripheral = mock([CBPeripheral class]);
    servicesManager = [[WLXServicesManager alloc] initWithPeripheral:peripheral notificationCenter:notificationCenter];
});

describe(@"#rac_discoverServices", ^{
    
    __block RACSignal * signal;
    
    afterEach(^{
        signal = nil;
        servicesManager = nil;
    });
    
    context(@"when the services discovery process succeeds", ^{
        
        it(@"returns a signal that complets", ^{ waitUntil(^(DoneCallback done) {
            [[servicesManager rac_discoverServices] subscribeCompleted:^{
                done();
            }];
            [servicesManager peripheral:peripheral didDiscoverServices:nil];
        });});
        
    });
    
    context(@"when the services discovery process fails", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"" code:0 userInfo:nil];
        });
        
        it(@"returns a signal that errors", ^{ waitUntil(^(DoneCallback done) {
            [[servicesManager rac_discoverServices] subscribeError:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            [servicesManager peripheral:peripheral didDiscoverServices:error];
        });});
        
    });
    
});

SpecEnd