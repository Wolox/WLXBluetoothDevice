
//
//  WLXCharacteristicAsyncExecutor.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/22/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXCharacteristicAsyncExecutor.h>
#import <WLXBluetoothDevice/WLXCharacteristicLocator.h>

SpecBegin(WLXCharacteristicAsyncExecutor)

    __block id<WLXCharacteristicLocator> mockLocator;
    __block WLXCharacteristicAsyncExecutor * asyncExecutor;
    __block CBUUID * characteristicUUID;
    __block CBCharacteristic * mockCharacteristic;

    beforeEach(^{
        mockLocator = mockProtocol(@protocol(WLXCharacteristicLocator));
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        asyncExecutor = [[WLXCharacteristicAsyncExecutor alloc] initWithCharacteristicLocator:mockLocator queue:queue];
        characteristicUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
        mockCharacteristic = mock([CBCharacteristic class]);
        [MKTGiven(mockCharacteristic.UUID) willReturn:characteristicUUID];
    });

    afterEach(^{
        mockLocator = nil;
        asyncExecutor = nil;
        characteristicUUID = nil;
        mockCharacteristic = nil;
    });

    describe(@"executeBlock:forCharacteristic:", ^{
        
        context(@"when the characteristic has already been discovered", ^{
        
            beforeEach(^{
                [MKTGiven([mockLocator characteristicFromUUID:characteristicUUID]) willReturn:mockCharacteristic];
            });
            
            it(@"executes the block immediately", ^{ waitUntil(^(DoneCallback done) {
                [asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic){
                    expect(error).to.beNil;
                    expect(characteristic).to.equal(mockCharacteristic);
                    done();
                } forCharacteristic:characteristicUUID];
            });});
            
        });
        
        context(@"when the characteristic has not been discovered", ^{
        
            beforeEach(^{
                [MKTGiven([mockLocator characteristicFromUUID:characteristicUUID]) willReturn:nil];
            });
            
            context(@"when there are pending operations for the given characteristic", ^{
                
                beforeEach(^{
                    [asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
                        
                    } forCharacteristic:characteristicUUID];
                });
                
                it(@"does not tell the characteristic locator to discover the characteristic", ^{
                    [asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
                        
                    } forCharacteristic:characteristicUUID];
                    [MKTVerifyCount(mockLocator, times(1)) discoverCharacteristics:@[characteristicUUID]];
                });
                
                it(@"increments the amount of pending operations", ^{
                    NSUInteger pendingOperations = [asyncExecutor pendingOperationsCountForCharacteristic:characteristicUUID];
                    [asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
                        
                    } forCharacteristic:characteristicUUID];
                    expect([asyncExecutor pendingOperationsCountForCharacteristic:characteristicUUID]).to.equal(pendingOperations + 1);
                });
                
            });
            
            it(@"tells the characteristic locator to discover the characteristic", ^{
                [asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
                    
                } forCharacteristic:characteristicUUID];
                [MKTVerify(mockLocator) discoverCharacteristics:@[characteristicUUID]];
            });
            
            it(@"increments the amount of pending operations", ^{
                NSUInteger pendingOperations = [asyncExecutor pendingOperationsCountForCharacteristic:characteristicUUID];
                [asyncExecutor executeBlock:^(NSError * error, CBCharacteristic * characteristic) {
                    
                } forCharacteristic:characteristicUUID];
                expect([asyncExecutor pendingOperationsCountForCharacteristic:characteristicUUID]).to.equal(pendingOperations + 1);
            });
            
        });
        
    });


    describe(@"flushPendingOperations", ^{
        
        __block void(^block)(NSError *, CBCharacteristic *);
        
        context(@"when there are pending operations for the discovered characteristics", ^{
        
            beforeEach(^{
                [MKTGiven([mockLocator characteristicFromUUID:characteristicUUID]) willReturn:nil];
                [MKTGiven(mockLocator.characteristics) willReturn:@[mockCharacteristic]];
            });
            
            it(@"executes the pending operations", ^{
                block = ^(NSError * error, CBCharacteristic * characteristic) {
                    expect(error).to.beNil;
                    expect(characteristic).to.equal(mockCharacteristic);
                };
                [asyncExecutor executeBlock:block forCharacteristic:characteristicUUID];
                [asyncExecutor flushPendingOperations];
            });
            
        });
        
    });

    describe(@"flushPendingOperationsWithError:", ^{
        
        __block void(^block)(NSError *, CBCharacteristic *);
        
        context(@"when there are pending operations for the discovered characteristics", ^{
            
            beforeEach(^{
                [MKTGiven([mockLocator characteristicFromUUID:characteristicUUID]) willReturn:nil];
                [MKTGiven(mockLocator.characteristics) willReturn:@[mockCharacteristic]];
            });
            
            it(@"executes the pending operations", ^{
                block = ^(NSError * error, CBCharacteristic * characteristic) {
                    expect(error).notTo.beNil;
                    expect(characteristic).to.beNil;                };
                [asyncExecutor executeBlock:block forCharacteristic:characteristicUUID];
                NSError * error = [NSError errorWithDomain:@"foo" code:0 userInfo:nil];
                [asyncExecutor flushPendingOperationsWithError:error];
            });
            
        });
        
    });


SpecEnd