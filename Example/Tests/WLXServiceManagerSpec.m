//
//  WLXServiceManagerSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/22/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXServiceManager.h>

#define VerifyAfter(timeout, mock)      \
    usleep(timeout), MKTVerify(mock)

@interface WLXCharacteristicObserver : NSObject

@property(nonatomic) NSData * data;
@property(nonatomic) NSError * error;

- (void)updatedValue:(NSData *)data error:(NSError *)error;

@end

@implementation WLXCharacteristicObserver

- (void)updatedValue:(NSData *)data error:(NSError *)error {
    self.data = data;
    self.error = error;
}

@end

SpecBegin(WLXServiceManager)

    __block id<WLXCharacteristicLocator> mockLocator;
    __block CBPeripheral * mockPeripheral;
    __block CBService * mockService;
    __block WLXCharacteristicAsyncExecutor * asyncExecutor;
    __block WLXServiceManager * serviceManager;

    __block CBUUID * characteristicUUID;
    __block CBCharacteristic * mockCharacteristic;
    __block NSData * data;
    __block NSError * error;

    beforeEach(^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        mockLocator = mockProtocol(@protocol(WLXCharacteristicLocator));
        mockPeripheral = mock([CBPeripheral class]);
        mockService = mock([CBService class]);
        asyncExecutor = [[WLXCharacteristicAsyncExecutor alloc] initWithCharacteristicLocator:mockLocator queue:queue];
        serviceManager = [[WLXServiceManager alloc] initWithPeripheral:mockPeripheral service:mockService];
        serviceManager.asyncExecutor = asyncExecutor;
        
        characteristicUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
        mockCharacteristic = mock([CBCharacteristic class]);
        [MKTGiven(mockCharacteristic.UUID) willReturn:characteristicUUID];
        [MKTGiven([mockLocator characteristicFromUUID:characteristicUUID]) willReturn:mockCharacteristic];
    });

    afterEach(^{
        mockLocator = nil;
        mockPeripheral = nil;
        mockService = nil;
        asyncExecutor = nil;
        serviceManager = nil;
        characteristicUUID = nil;
        data = nil;
        error = nil;
    });

    describe(@"#readValueForCharacteristicUUID:usingBlock:", ^{
        
        context(@"when a nil UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{ [serviceManager readValueForCharacteristicUUID:nil usingBlock:^(NSError * error, NSData * data) {
                    
                }]; }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager readValueForCharacteristicUUID:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the value is successfully read", ^{
        
            beforeEach(^{
                data = [[NSData alloc] init];
                [MKTGiven(mockCharacteristic.value) willReturn:data];
            });
            
            it(@"calls the block with the read data", ^AsyncBlock{
                [serviceManager readValueForCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    expect(error).to.beNil;
                    expect(data).to.equal(data);
                    done();
                }];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil];
            });
            
            it(@"calls the peripheral's readValueForCharacteristic", ^AsyncBlock{
                [serviceManager readValueForCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    done();
                }];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil];
            });
        
        });
        
        context(@"when there is an error reading the value", ^{
        
            beforeEach(^{
                error = [NSError errorWithDomain:@"ar.com.wolox.Test" code:0 userInfo:nil];
            });
            
            it(@"call the block with an error", ^AsyncBlock{
                [serviceManager readValueForCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    expect(error).notTo.beNil;
                    expect(data).to.beNil;
                    done();
                }];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error];
            });
            
            it(@"calls the peripheral's readValueForCharacteristic", ^AsyncBlock{
                [serviceManager readValueForCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    done();
                }];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error];
            });
            
        });
    
        
    });

    describe(@"#writeValue:forCharacteristicUUID:usingBlock:", ^{
        
        beforeEach(^{
            data = [[NSData alloc] init];
            [MKTGiven(mockCharacteristic.value) willReturn:data];
        });
        
        context(@"when a nil data is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:nil forCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error){}];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:data forCharacteristicUUID:nil usingBlock:^(NSError * error){}];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:data forCharacteristicUUID:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the characteristic's value is successfully writen", ^{
        
            it(@"calls the block with a nil error", ^AsyncBlock{
                [serviceManager writeValue:data forCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                [serviceManager didWriteValueForCharacteristic:mockCharacteristic error:nil];
            });
            
            it(@"calls the peripheral's writeValue:forCharacteristic:type: method", ^AsyncBlock{
                [serviceManager writeValue:data forCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) writeValue:data forCharacteristic:mockCharacteristic type:CBCharacteristicWriteWithResponse];
                    done();
                }];
                [serviceManager didWriteValueForCharacteristic:mockCharacteristic error:nil];
            });
        
        });
        
        context(@"when the characteristic's value could not be writen", ^{
        
            it(@"calls the block with an error", ^AsyncBlock{
                [serviceManager writeValue:data forCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                [serviceManager didWriteValueForCharacteristic:mockCharacteristic error:error];
            });
            
            it(@"calls the peripheral's writeValue:forCharacteristic:type: method", ^AsyncBlock{
                [serviceManager writeValue:data forCharacteristicUUID:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) writeValue:data forCharacteristic:mockCharacteristic type:CBCharacteristicWriteWithResponse];
                    done();
                }];
                [serviceManager didWriteValueForCharacteristic:mockCharacteristic error:error];
            });
            
        });
        
    });

    describe(@"#writeValue:forCharacteristicUUID:", ^{
        
        beforeEach(^{
            data = [[NSData alloc] init];
            [MKTGiven(mockCharacteristic.value) willReturn:data];
        });
        
        context(@"when a nil data is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:nil forCharacteristicUUID:characteristicUUID];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:data forCharacteristicUUID:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        it(@"calls the peripheral's writeValue:forCharacteristic:type: method", ^{
            [serviceManager writeValue:data forCharacteristicUUID:characteristicUUID];
            // This sleep is necesary because all the bluetooth related operations are
            // performed async.
            [VerifyAfter(100, mockPeripheral) writeValue:data forCharacteristic:mockCharacteristic type:CBCharacteristicWriteWithoutResponse];
        });
        
    });

    describe(@"#enableNotificationsForCharacteristic:usingBlock:", ^{
    
        context(@"when a nil characteristic UUID is given", ^{
        
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager enableNotificationsForCharacteristic:nil usingBlock:^(NSError * error) {}];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
        
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the notifications are successfully enabled", ^{
        
            it(@"calls the block", ^AsyncBlock{
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil];
            });
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^AsyncBlock{
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:YES forCharacteristic:mockCharacteristic];
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil];
            });
            
        });
        
        context(@"when the notifications could not be enabled", ^{
        
            it(@"calls the block witn an error", ^AsyncBlock{
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error];
            });
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^AsyncBlock{
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:YES forCharacteristic:mockCharacteristic];
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error];
            });
        
        });
        
    });

    describe(@"#disableNotificationsForCharacteristic:usingBlock:", ^{
    
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager disableNotificationsForCharacteristic:nil usingBlock:^(NSError * error) {}];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the notifications are successfully enabled", ^{
            
            it(@"calls the block", ^AsyncBlock{
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil];
            });
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^AsyncBlock{
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:NO forCharacteristic:mockCharacteristic];
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil];
            });
            
        });
        
        context(@"when the notifications could not be enabled", ^{
            
            it(@"calls the block witn an error", ^AsyncBlock{
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error];
            });
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^AsyncBlock{
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:YES forCharacteristic:mockCharacteristic];
                    done();
                }];
                [serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error];
            });
            
        });
        
    });

    describe(@"#addObserverForCharacteristic:usingBlock:", ^{
    
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                id block = ^(NSError * error, NSData * data) {};
                expect(^{
                    [serviceManager addObserverForCharacteristic:nil usingBlock:block];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
        
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
        
        });
        
        context(@"when a notification is received for the observed characteristic", ^{
            
            beforeEach(^{
                data = [[NSData alloc] init];
                [MKTGiven(mockCharacteristic.value) willReturn:data];
            });
        
            it(@"calls the block with the updated data", ^AsyncBlock{
                [serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * aData) {
                    expect(error).to.beNil;
                    expect(aData).to.equal(data);
                    done();
                }];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil];
            });
            
        });
        
        context(@"when a notification error is received for the observed characteristic", ^{
        
            it(@"calls the block with an error", ^AsyncBlock{
                [serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * aData) {
                    expect(error).notTo.beNil;
                    expect(aData).to.beNil;
                    done();
                }];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error];
            });
            
        });
        
        it(@"returns the created observer", ^{
            id block = ^(NSError * error, NSData * data) {};
            expect([serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:block]).notTo.beNil;
        });
        
    });

    describe(@"#addObserverForCharacteristic:selector:target:", ^{
    
        __block WLXCharacteristicObserver * observer;
        
        beforeEach(^{
            observer = [[WLXCharacteristicObserver alloc] init];
        });
        
        afterEach(^{
            observer = nil;
        });
        
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager addObserverForCharacteristic:nil selector:@selector(updatedValue:error:) target:observer];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a notification is received for the observed characteristic", ^{
            
            beforeEach(^{
                data = [[NSData alloc] init];
                [MKTGiven(mockCharacteristic.value) willReturn:data];
            });
            
            it(@"calls the block with the updated data", ^{
                [serviceManager addObserverForCharacteristic:characteristicUUID selector:@selector(updatedValue:error:) target:observer];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil];
                // This has to be done like this because all bluetooth related operation are executed async and
                // we cannot mock the object that is the target due to an implementation detail.
                usleep(100);
                expect(observer.data).to.equal(data);
                expect(observer.error).to.beNil;
            });
            
        });
        
        context(@"when a notification error is received for the observed characteristic", ^{
            
            it(@"calls the block with an error", ^{
                [serviceManager addObserverForCharacteristic:characteristicUUID selector:@selector(updatedValue:error:) target:observer];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error];
                // This has to be done like this because all bluetooth related operation are executed async and
                // we cannot mock the object that is the target due to an implementation detail.
                usleep(100);
                expect(observer.data).to.beNil;
                expect(observer.error).notTo.beNil;
            });
            
        });
        
        it(@"returns the created observer", ^{
            expect([serviceManager addObserverForCharacteristic:characteristicUUID selector:@selector(updatedValue:error:) target:observer]).notTo.beNil;
        });
        
    });

    describe(@"#removeObserver:", ^{
        
        __block WLXCharacteristicObserver * observer;
        
        beforeEach(^{
            observer = [[WLXCharacteristicObserver alloc] init];
            data = [[NSData alloc] init];
            [MKTGiven(mockCharacteristic.value) willReturn:data];
        });
        
        afterEach(^{
            observer = nil;
        });
    
        context(@"when the observer is nil", ^{
        
        });
        
        it(@"stops notifying value updates to the removed observer", ^{
            id opaqueObserver = [serviceManager addObserverForCharacteristic:characteristicUUID
                                                                    selector:@selector(updatedValue:error:)
                                                                      target:observer];
            [serviceManager removeObserver:opaqueObserver];
            [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil];
            usleep(100);
            expect(observer.data).to.beNil;
            expect(observer.error).to.beNil;
            
        });
        
    });


SpecEnd