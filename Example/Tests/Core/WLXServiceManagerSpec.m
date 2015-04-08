//
//  WLXServiceManagerSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/22/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXServiceManager.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>

#define ASYNC(code)                     \
    dispatch_async(specQueue, ^{ code; })

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
    __block NSNotificationCenter * notificationCenter;

    __block CBUUID * characteristicUUID;
    __block CBCharacteristic * mockCharacteristic;
    __block NSData * data;
    __block NSError * error;
    __block dispatch_queue_t specQueue;

    beforeEach(^{
        // DO NOT change this queue. It MUST be a serial queue, in order to guarantee that the tasks
        // are processed in the arrival order. This queue must be the dispatch queue used by the
        // async executor and every time we perform an operation that requires a characteristic UUID
        // and then we 'fake' a call to didXXXX method on the WLXServiceManager with MUST wrap that
        // with the ASYNC macro. That will assure that all the book keeping operation that are performed
        // async on the async executor are executed BEFORE any other operation triggered by the didXXX
        // methods. If not a determistic behavior for the spec is not guaranted.
        specQueue = dispatch_queue_create("ar.com.wolox.WLXBluetoothDevice.Specs", DISPATCH_QUEUE_SERIAL);
        characteristicUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
        CBUUID * serviceUUID = [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00068"];
        mockLocator = mockProtocol(@protocol(WLXCharacteristicLocator));
        mockPeripheral = mock([CBPeripheral class]);
        mockService = mock([CBService class]);
        mockCharacteristic = mock([CBCharacteristic class]);
        notificationCenter = [NSNotificationCenter defaultCenter];
        [MKTGiven(mockCharacteristic.UUID) willReturn:characteristicUUID];
        [MKTGiven([mockLocator characteristicFromUUID:characteristicUUID]) willReturn:mockCharacteristic];
        [MKTGiven(mockService.UUID) willReturn:serviceUUID];
        
        asyncExecutor = [[WLXCharacteristicAsyncExecutor alloc] initWithCharacteristicLocator:mockLocator queue:specQueue];
        serviceManager = [[WLXServiceManager alloc] initWithPeripheral:mockPeripheral
                                                               service:mockService
                                                    notificationCenter:notificationCenter];
        serviceManager.asyncExecutor = asyncExecutor;
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

    describe(@"#invalidated", ^{
        
        context(@"when the service manager has just been created", ^{
            
            it(@"is not invalidated", ^{
                expect(serviceManager.invalidated).to.beFalsy;
            });
            
        });
        
        context(@"when a WLXBluetoothDeviceReconnecting notification is triggered", ^{
            
            beforeEach(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"is invalidated", ^{
                expect(serviceManager.invalidated).to.beTruthy;
            });
            
        });
        
        context(@"when a WLXBluetoothDeviceConnectionLost notification is triggered", ^{
            
            beforeEach(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionLost object:nil];
            });
            
            it(@"is invalidated", ^{
                expect(serviceManager.invalidated).to.beTruthy;
            });
            
        });
        
        context(@"when a WLXBluetoothDeviceConnectionTerminated notification is triggered", ^{
            
            beforeEach(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionTerminated object:nil];
            });
            
            it(@"is invalidated", ^{
                expect(serviceManager.invalidated).to.beTruthy;
            });
            
        });
        
    });

    describe(@"#readValueFromCharacteristic:usingBlock:", ^{
        
        context(@"when a nil UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{ [serviceManager readValueFromCharacteristic:nil usingBlock:^(NSError * error, NSData * data) {
                    
                }]; }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager readValueFromCharacteristic:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the value is successfully read", ^{
        
            beforeEach(^{
                data = [[NSData alloc] init];
                [MKTGiven(mockCharacteristic.value) willReturn:data];
            });
            
            it(@"calls the block with the read data", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager readValueFromCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    expect(error).to.beNil;
                    expect(data).to.equal(data);
                    done();
                }];
                ASYNC([serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil]);
            });});
            
            it(@"calls the peripheral's readValueForCharacteristic", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager readValueFromCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    done();
                }];
                ASYNC([serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil]);
            });});
        
        });
        
        context(@"when there is an error reading the value", ^{
        
            beforeEach(^{
                error = [NSError errorWithDomain:@"ar.com.wolox.Test" code:0 userInfo:nil];
            });
            
            it(@"call the block with an error", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager readValueFromCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    expect(error).notTo.beNil;
                    expect(data).to.beNil;
                    done();
                }];
                ASYNC([serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error]);
            });});
            
            it(@"calls the peripheral's readValueForCharacteristic", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager readValueFromCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
                    [MKTVerify(mockPeripheral) readValueForCharacteristic:mockCharacteristic];
                    done();
                }];
                ASYNC([serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error]);
            });});
            
        });
    
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager readValueFromCharacteristic:characteristicUUID
                                                     usingBlock:^(NSError * error, NSData * data) {}];
                }).to.raise(NSInternalInconsistencyException);
            });
            
        });
        
    });

    describe(@"#writeValue:toCharacteristic:usingBlock:", ^{
        
        beforeEach(^{
            data = [[NSData alloc] init];
            [MKTGiven(mockCharacteristic.value) willReturn:data];
        });
        
        context(@"when a nil data is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:nil toCharacteristic:characteristicUUID usingBlock:^(NSError * error){}];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:data toCharacteristic:nil usingBlock:^(NSError * error){}];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil block is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:data toCharacteristic:characteristicUUID usingBlock:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the characteristic's value is successfully writen", ^{
        
            it(@"calls the block with a nil error", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager writeValue:data toCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                ASYNC([serviceManager didWriteValueForCharacteristic:mockCharacteristic error:nil]);
            });});
            
            it(@"calls the peripheral's writeValue:forCharacteristic:type: method", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager writeValue:data toCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) writeValue:data forCharacteristic:mockCharacteristic type:CBCharacteristicWriteWithResponse];
                    done();
                }];
                ASYNC([serviceManager didWriteValueForCharacteristic:mockCharacteristic error:nil]);
            });});
        
        });
        
        context(@"when the characteristic's value could not be writen", ^{
        
            it(@"calls the block with an error", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager writeValue:data toCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                ASYNC([serviceManager didWriteValueForCharacteristic:mockCharacteristic error:error]);
            });});
            
            it(@"calls the peripheral's writeValue:forCharacteristic:type: method", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager writeValue:data toCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) writeValue:data forCharacteristic:mockCharacteristic type:CBCharacteristicWriteWithResponse];
                    done();
                }];
                ASYNC([serviceManager didWriteValueForCharacteristic:mockCharacteristic error:error]);
            });});
            
        });
        
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager writeValue:data
                              toCharacteristic:characteristicUUID
                                    usingBlock:^(NSError * error) {}];
                }).to.raise(NSInternalInconsistencyException);
            });
            
        });
        
    });

    describe(@"#writeValue:toCharacteristic:", ^{
        
        beforeEach(^{
            data = [[NSData alloc] init];
            [MKTGiven(mockCharacteristic.value) willReturn:data];
        });
        
        context(@"when a nil data is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:nil toCharacteristic:characteristicUUID];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when a nil characteristic UUID is given", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [serviceManager writeValue:data toCharacteristic:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        it(@"calls the peripheral's writeValue:forCharacteristic:type: method", ^{ waitUntil(^(DoneCallback done) {
            [serviceManager writeValue:data toCharacteristic:characteristicUUID];
            ASYNC({
                [MKTVerify(mockPeripheral) writeValue:data forCharacteristic:mockCharacteristic type:CBCharacteristicWriteWithoutResponse];
                done();
            });
        });});
        
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager writeValue:data
                              toCharacteristic:characteristicUUID];
                }).to.raise(NSInternalInconsistencyException);
            });
            
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
        
            it(@"calls the block", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil]);
            });});
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:YES forCharacteristic:mockCharacteristic];
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil]);
            });});
            
        });
        
        context(@"when the notifications could not be enabled", ^{
        
            it(@"calls the block witn an error", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error]);
            });});
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:YES forCharacteristic:mockCharacteristic];
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error]);
            });});
        
        });
        
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager enableNotificationsForCharacteristic:characteristicUUID
                                                              usingBlock:^(NSError * error) {}];
                }).to.raise(NSInternalInconsistencyException);
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
            
            it(@"calls the block", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil]);
            });});
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:NO forCharacteristic:mockCharacteristic];
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:nil]);
            });});
            
        });
        
        context(@"when the notifications could not be enabled", ^{
            
            it(@"calls the block witn an error", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    expect(error).notTo.beNil;
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error]);
            });});
            
            it(@"calls the peripheral's setNotifyValue:forCharacteristic method", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
                    [MKTVerify(mockPeripheral) setNotifyValue:YES forCharacteristic:mockCharacteristic];
                    done();
                }];
                ASYNC([serviceManager didUpdateNotificationStateForCharacteristic:mockCharacteristic error:error]);
            });});
            
        });
        
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager disableNotificationsForCharacteristic:characteristicUUID
                                                               usingBlock:^(NSError * error) {}];
                }).to.raise(NSInternalInconsistencyException);
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
        
            it(@"calls the block with the updated data", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * aData) {
                    expect(error).to.beNil;
                    expect(aData).to.equal(data);
                    done();
                }];
                ASYNC([serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:nil]);
            });});
            
        });
        
        context(@"when a notification error is received for the observed characteristic", ^{
        
            it(@"calls the block with an error", ^{ waitUntil(^(DoneCallback done) {
                [serviceManager addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * aData) {
                    expect(error).notTo.beNil;
                    expect(aData).to.beNil;
                    done();
                }];
                ASYNC([serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error]);
            });});
            
        });
        
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager addObserverForCharacteristic:characteristicUUID
                                                      usingBlock:^(NSError * error, NSData * aData) {}];
                }).to.raise(NSInternalInconsistencyException);
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
                ASYNC({
                    expect(observer.data).to.equal(data);
                    expect(observer.error).to.beNil;                
                });
            });
            
        });
        
        context(@"when a notification error is received for the observed characteristic", ^{
            
            it(@"calls the block with an error", ^{
                [serviceManager addObserverForCharacteristic:characteristicUUID selector:@selector(updatedValue:error:) target:observer];
                [serviceManager didUpdateValueForCharacteristic:mockCharacteristic error:error];
                ASYNC({
                    expect(observer.data).to.beNil;
                    expect(observer.error).notTo.beNil;
                });
            });
            
        });
        
        context(@"when the service manager has been invalidated", ^{
            
            before(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceReconnecting object:nil];
            });
            
            it(@"raises an exepction", ^{
                expect(^{
                    [serviceManager addObserverForCharacteristic:nil
                                                        selector:@selector(updatedValue:error:)
                                                          target:observer];
                }).to.raise(NSInternalInconsistencyException);
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