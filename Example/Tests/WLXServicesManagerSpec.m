//
//  WLXServicesManagerSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/31/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXServicesManager.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>

SpecBegin(WLXServicesManager)

    __block CBPeripheral * mockPeripheral;
    __block CBService * mockService;
    __block WLXServicesManager * servicesManager;
    __block NSNotificationCenter * notificationCenter;

    beforeEach(^{
        mockPeripheral = mock([CBPeripheral class]);
        mockService = mock([CBService class]);
        notificationCenter = [NSNotificationCenter defaultCenter];
        servicesManager = [[WLXServicesManager alloc] initWithPeripheral:mockPeripheral notificationCenter:notificationCenter];
        
        CBUUID * serviceUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
        [MKTGiven(mockService.UUID) willReturn:serviceUUID];
    });

    afterEach(^{
        mockPeripheral = nil;
        mockService = nil;
        servicesManager = nil;
        notificationCenter = nil;
    });

    describe(@"#discoverServicesUsingBlock:", ^{
        
        context(@"when the services where successfully discovered", ^{
        
            beforeEach(^{
                [MKTGiven(mockPeripheral.services) willReturn:@[mockService]];
            });
            
            it(@"calls the block", ^AsyncBlock{
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                [servicesManager peripheral:mockPeripheral didDiscoverServices:nil];
            });
            
            it(@"calls the peripheral's discoverServices: method", ^AsyncBlock{
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) discoverServices:nil];
                    done();
                }];
                [servicesManager peripheral:mockPeripheral didDiscoverServices:nil];
            });
            
            it(@"stores the discovered services", ^AsyncBlock{
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {
                    expect(servicesManager.services).to.equal(@[mockService]);
                    done();
                }];
                [servicesManager peripheral:mockPeripheral didDiscoverServices:nil];
            });
            
            it(@"returns YES", ^{
                expect([servicesManager discoverServicesUsingBlock:^(NSError * error) {}]).to.beTruthy;
            });
            
        });
        
        context(@"when there is an error discovering the services", ^{
           
            __block NSError * error;
            
            beforeEach(^{
                error = [NSError errorWithDomain:@"ar.com.wolox.foo" code:0 userInfo:nil];
            });
            
            afterEach(^{
                error = nil;
            });
            
            it(@"calls the block with an error", ^AsyncBlock{
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                [servicesManager peripheral:mockPeripheral didDiscoverServices:error];
            });
            
        });
        
        context(@"when the discovery process has already been started", ^{
        
            beforeEach(^{
                [MKTGiven(mockPeripheral.services) willReturn:@[mockService]];
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {}];
            });
            
            it(@"returns NO", ^{
                expect([servicesManager discoverServicesUsingBlock:^(NSError * error) {}]).to.beFalsy;
            });
            
            it(@"calls the block with an error", ^AsyncBlock{
                NSError * error = [NSError errorWithDomain:WLXBluetoothDeviceServiceErrorDomain
                                                      code:WLXBluetoothDeviceServiceErrorServicesDiscoveryAlreadyStarted
                                                  userInfo:nil];
                [servicesManager discoverServicesUsingBlock:^(NSError * anError) {
                    expect(anError).to.equal(error);
                    done();
                }];
            });
            
            it(@"does not call the peripheral's discoverServices: methods", ^AsyncBlock{
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {
                    [MKTVerifyCount(mockPeripheral, times(1)) discoverServices:nil];
                    done();
                }];
            });
            
        });
        
        context(@"when the connection is lost while discovering", ^{
        
            beforeEach(^{
                [MKTGiven(mockPeripheral.services) willReturn:@[mockService]];
                [servicesManager discoverServicesUsingBlock:^(NSError * error) {}];
            });
            
            it(@"stops discovering services", ^{
                expect(servicesManager.discovering).to.equal(YES);
                [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOff object:nil];
                expect(servicesManager.discovering).to.equal(NO);
            });
            
        });
        
    });

    describe(@"#serviceFromUUID:", ^{
        
        context(@"when a nil service UUID is given", ^{
        
            it(@"raises an exception", ^{
                expect(^{ [servicesManager serviceFromUUID:nil]; }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
    
        context(@"when the service has been discovered", ^{
        
            beforeEach(^{
                [servicesManager discoverServicesUsingBlock:nil];
                [MKTGiven(mockPeripheral.services) willReturn:@[mockService]];
                [servicesManager peripheral:mockPeripheral didDiscoverServices:nil];
            });
            
            it(@"returns the service", ^{
                expect([servicesManager serviceFromUUID:mockService.UUID]).to.equal(mockService);
            });
            
        });
        
        context(@"when the service has not been discovered", ^{
        
            it(@"returns nil", ^{
                expect([servicesManager serviceFromUUID:mockService.UUID]).to.beNil;
            });
            
        });
        
    });

    describe(@"#managerForService:", ^{
        
        context(@"when a nil service UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{ [servicesManager managerForService:nil]; }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the service has been discovered", ^{
            
            beforeEach(^{
                [servicesManager discoverServicesUsingBlock:nil];
                [MKTGiven(mockPeripheral.services) willReturn:@[mockService]];
                [servicesManager peripheral:mockPeripheral didDiscoverServices:nil];
            });
            
            it(@"returns the manager", ^{
                expect([servicesManager managerForService:mockService.UUID]).notTo.beNil;
            });
            
        });
        
        context(@"when the service has not been discovered", ^{
            
            it(@"returns nil", ^{
                expect([servicesManager managerForService:mockService.UUID]).to.beNil;
            });
            
        });
    
    });


SpecEnd