//
//  WLXServiceManager+RACSignalSupportSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 3/11/15.
//  Copyright (c) 2015 Guido Marucci Blas. All rights reserved.
//
#import "SpecHelper.h"

#define STUB_ASYNC_EXECUTOR(e)                                                                              \
    do {                                                                                                    \
        MKTArgumentCaptor * argument = [[MKTArgumentCaptor alloc] init];                                    \
        [MKTVerify(asyncExecutor) executeBlock:argument.capture forCharacteristic:characteristicUUID];      \
        void(^executeBlock)(NSError *, CBCharacteristic *) = argument.value;                                \
        executeBlock(e, characteristic);                                                                    \
    } while (0)

SpecBegin(WLXServiceManager_RACSignalSupport)

__block CBPeripheral * peripheral;
__block CBService * service;
__block WLXCharacteristicAsyncExecutor * asyncExecutor;
__block CBCharacteristic * characteristic;
__block CBUUID * characteristicUUID;
__block WLXServiceManager * serviceManager;
__block NSNotificationCenter * notificationCenter;

beforeEach(^{
    notificationCenter = [NSNotificationCenter defaultCenter];
    characteristicUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    characteristic = mock([CBCharacteristic class]);
    peripheral = mock([CBPeripheral class]);
    service = mock([CBService class]);
    asyncExecutor = mock([WLXCharacteristicAsyncExecutor class]);
    serviceManager = [[WLXServiceManager alloc] initWithPeripheral:peripheral
                                                           service:service
                                                notificationCenter:notificationCenter];
    serviceManager.asyncExecutor = asyncExecutor;
    [MKTGiven([characteristic UUID]) willReturn:characteristicUUID];
    
});

describe(@"#rac_readValueFromCharacteristic:", ^{
   
    context(@"when the value is successfully read", ^{
        
        __block NSData * data;
        
        beforeEach(^{
            data = [NSMutableData data];
            [MKTGiven(characteristic.value) willReturn:data];
        });
        
        it(@"returns a signal that sends the value", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_readValueFromCharacteristic:characteristicUUID] subscribeNext:^(NSData * value) {
                expect(value).to.equal(data);
                done();
            }];
            
            STUB_ASYNC_EXECUTOR(nil);
            [serviceManager didUpdateValueForCharacteristic:characteristic error:nil];
        });});
        
    });
    
    context(@"when the value could not be read", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"" code:1 userInfo:nil];
        });
        
        it(@"returns a signal that errors", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_readValueFromCharacteristic:characteristicUUID] subscribeError:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            STUB_ASYNC_EXECUTOR(error);
            [serviceManager didUpdateValueForCharacteristic:characteristic error:error];
        });});
        
    });
    
});

describe(@"#rac_writeValue:toCharacteristic:", ^{

    __block NSData * data;
    
    beforeEach(^{
        data = [NSMutableData data];
    });
    
    context(@"when the value is successfully writtern", ^{
       
        it(@"returns a signal that completes", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_writeValue:data toCharacteristic:characteristicUUID] subscribeCompleted:^{
                done();
            }];
            STUB_ASYNC_EXECUTOR(nil);
            [serviceManager didWriteValueForCharacteristic:characteristic error:nil];
        });});
        
    });
    
    context(@"when the value could not be written", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"" code:1 userInfo:nil];
        });
        
        it(@"returns a signal that errors", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_writeValue:data toCharacteristic:characteristicUUID] subscribeError:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            STUB_ASYNC_EXECUTOR(error);
            [serviceManager didWriteValueForCharacteristic:characteristic error:error];
        });});
        
    });
    
});

describe(@"#rac_enableNotificationsForCharacteristic:", ^{
   
    context(@"when the notification are successfully enabled", ^{
        
        it(@"returns a signal that complets", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_enableNotificationsForCharacteristic:characteristicUUID] subscribeCompleted:^{
                done();
            }];
            STUB_ASYNC_EXECUTOR(nil);
            [serviceManager didUpdateNotificationStateForCharacteristic:characteristic error:nil];
        });});
        
    });
    
    context(@"when the notification could not be enabled", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"" code:1 userInfo:nil];
        });
        
        it(@"returns a signal that errors", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_enableNotificationsForCharacteristic:characteristicUUID] subscribeError:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            STUB_ASYNC_EXECUTOR(nil);
            [serviceManager didUpdateNotificationStateForCharacteristic:characteristic error:error];
        });});
        
    });
    
});

describe(@"#rac_disableNotificationsForCharacteristic:", ^{
    
    context(@"when the notification are successfully disabled", ^{
        
        it(@"returns a signal that completes", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_disableNotificationsForCharacteristic:characteristicUUID] subscribeCompleted:^{
                done();
            }];
            STUB_ASYNC_EXECUTOR(nil);
            [serviceManager didUpdateNotificationStateForCharacteristic:characteristic error:nil];
        });});
        
    });
    
    context(@"when the notification could not be disabled", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"" code:1 userInfo:nil];
        });
        
        it(@"returns a signal that errors", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_disableNotificationsForCharacteristic:characteristicUUID] subscribeError:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            STUB_ASYNC_EXECUTOR(error);
            [serviceManager didUpdateNotificationStateForCharacteristic:characteristic error:error];
        });});
        
    });
    
});

describe(@"#rac_notificationsForCharacteristic:", ^{
   
    __block NSData * data;
    
    beforeEach(^{
        data = [NSMutableData data];
        [MKTGiven(characteristic.value) willReturn:data];
    });
    
    context(@"when an update is received", ^{
        
        it(@"sends the received value to the signal", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_notificationsForCharacteristic:characteristicUUID] subscribeNext:^(NSData * value) {
                expect(value).to.equal(data);
                done();
            }];
            [serviceManager didUpdateValueForCharacteristic:characteristic error:nil];
        });});
        
    });
    
    context(@"when an error is received", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"" code:1 userInfo:nil];
        });
        
        it(@"sends the received value to the signal", ^{ waitUntil(^(DoneCallback done) {
            [[serviceManager rac_notificationsForCharacteristic:characteristicUUID] subscribeError:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            [serviceManager didUpdateValueForCharacteristic:characteristic error:error];
        });});
        
    });
    
});


SpecEnd