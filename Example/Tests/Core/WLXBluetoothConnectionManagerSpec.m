//
//  WLXBluetoothConnectionManagerSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/1/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXBluetoothConnectionManager.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceConnectionError.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>
#import <WLXBluetoothDevice/WLXLinearReconnectionStrategy.h>


SpecBegin(WLXBluetoothConnectionManager)

    __block CBPeripheral * mockPeripheral;
    __block CBCentralManager * mockCentralManager;
    __block NSNotificationCenter * notificationCenter;
    __block id<WLXReconnectionStrategy> mockReconnectionStrategy;
    __block WLXBluetoothConnectionManager * connectionManager;
    __block id<WLXConnectionManagerDelegate> connectionManagerDelegate;
    __block dispatch_queue_t queue;

    beforeEach(^{
        mockPeripheral = mock([CBPeripheral class]);
        mockCentralManager = mock([CBCentralManager class]);
        notificationCenter = [NSNotificationCenter defaultCenter];
        mockReconnectionStrategy = mockProtocol(@protocol(WLXReconnectionStrategy));
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        connectionManager = [[WLXBluetoothConnectionManager alloc] initWithPeripheral:mockPeripheral
                                                                       centralManager:mockCentralManager
                                                                   notificationCenter:notificationCenter
                                                                                queue:queue
                                                                 reconnectionStrategy:mockReconnectionStrategy
                                                                           bluetoohOn:NO];
        connectionManagerDelegate = mockProtocol(@protocol(WLXConnectionManagerDelegate));
        connectionManager.delegate = connectionManagerDelegate;
        [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOn object:nil userInfo:nil];
        NSUUID * peripheralUUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
        [MKTGiven(mockPeripheral.identifier) willReturn:peripheralUUID];
        [MKTGiven(mockPeripheral.name) willReturn:@"Mock Peripheral"];
    });

    afterEach(^{
        mockPeripheral = nil;
        mockCentralManager = nil;
        notificationCenter = nil;
        connectionManager = nil;
        connectionManagerDelegate = nil;
    });

    describe(@"#connectWithTimeout:usingBlock:", ^{
        
        it(@"tries to connect to the peripheral", ^{
            expect([connectionManager connectWithTimeout:0 usingBlock:nil]).to.beTruthy;
        });
        
        it(@"changes the connecting attribute", ^{
            expect(connectionManager.connecting).to.beFalsy;
            [connectionManager connectWithTimeout:0 usingBlock:nil];
            expect(connectionManager.connecting).to.beTruthy;
        });
        
        it(@"tells the central to connect with the peripheral", ^{
            [connectionManager connectWithTimeout:0 usingBlock:nil];
            [MKTVerify(mockCentralManager) connectPeripheral:mockPeripheral options:connectionManager.connectionOptions];
        });
        
        context(@"when a positive timout is given", ^{
            
            it(@"cancels the connection progress", ^{
                [connectionManager connectWithTimeout:200 usingBlock:nil];
                expect(connectionManager.connecting).to.beTruthy;
                expect(connectionManager.connecting).after(0.2).to.beFalsy;
            });
            
        });
        
        context(@"when the connection manager has alredy started a connection process", ^{
        
            beforeEach(^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
            });
            
            it(@"does not connect with the peripheral", ^{
                expect([connectionManager connectWithTimeout:0 usingBlock:nil]).to.beFalsy;
            });
            
            it(@"does not tell the central to connect with the peripheral", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [MKTVerifyCount(mockCentralManager, times(1)) connectPeripheral:mockPeripheral
                                                                        options:connectionManager.connectionOptions];

            });
            
            context(@"when a block is given", ^{
            
                it(@"passes a connection already started error", ^{
                    [connectionManager connectWithTimeout:0 usingBlock:^(NSError * error){
                        expect(error).to.equal(WLXConnectionAlreadyStartedError());
                    }];
                });
                
            });
        
        });
        
        context(@"when the connection manager is already connected", ^{
        
            beforeEach(^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [connectionManager didConnect];
            });
            
            it(@"does not connect with the peripheral", ^{
                expect([connectionManager connectWithTimeout:0 usingBlock:nil]).to.beFalsy;
            });
            
            it(@"does not tell the central to connect with the peripheral", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [MKTVerifyCount(mockCentralManager, times(1)) connectPeripheral:mockPeripheral
                                                                        options:connectionManager.connectionOptions];
                
            });
            
            context(@"when a block is given", ^{
                
                it(@"passes an already connected error", ^{
                    [connectionManager connectWithTimeout:0 usingBlock:^(NSError * error){
                        expect(error).to.equal(WLXAlreadyConnectedError());
                    }];
                });
                
            });
            
        });
        
        context(@"when bluetooth is off", ^{
            
            beforeEach(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOff object:nil userInfo:nil];
            });
            
            it(@"does not start the connection process", ^{
                expect([connectionManager connectWithTimeout:0 usingBlock:nil]).to.beFalsy;
            });
            
        });
        
    });

    describe(@"#disconnect", ^{
    
        beforeEach(^{
            [connectionManager connectWithTimeout:0 usingBlock:nil];
        });
        
        context(@"when the connection manager is connected", ^{
        
            beforeEach(^{
                [connectionManager didConnect];
            });
            
            it(@"tells the central to cancel the conneciton", ^{
                [connectionManager disconnect];
                [MKTVerify(mockCentralManager) cancelPeripheralConnection:mockPeripheral];
            });
            
        });
        
        context(@"when the conneciton manager is not connected", ^{
        
            it(@"does not tell the central to cancel the connection", ^{
                [MKTVerifyCount(mockCentralManager, never()) cancelPeripheralConnection:mockPeripheral];
            });
            
        });
        
        
    });

    describe(@"#didFailToConnect", ^{
    
        __block NSError * error;
        
        beforeEach(^{
            error = [NSError errorWithDomain:@"ar.com.wolox.WLXBluetoothDevice.ErrorTest" code:0 userInfo:nil];
        });
        
        afterEach(^{
            error = nil;
        });
        
        context(@"when the connection manager is not connecting", ^{
            
            it(@"raises an exception", ^{
                expect(^{
                    [connectionManager didFailToConnect:nil];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the connection manager is connecting", ^{
            
            it(@"changes the connecting attribute", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                expect(connectionManager.connecting).to.beTruthy;
                [connectionManager didFailToConnect:error];
                expect(connectionManager.connecting).to.beFalsy;
            });
            
            it(@"notifies about the error", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                NSDictionary * userInfo = @{ WLXBluetoothDeviceError : error };
                NSNotification * notification = [NSNotification notificationWithName:WLXBluetoothDeviceFailToConnect
                                                                              object:connectionManager
                                                                            userInfo:userInfo];
                expect(^{ [connectionManager didFailToConnect:error]; }).to.notify(notification);
            });
            
            it(@"invokes the delegate's connectionManager:didFailToConnect: method", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [connectionManager didFailToConnect:error];
                [MKTVerify(connectionManagerDelegate) connectionManager:connectionManager didFailToConnect:error];
            });
            
            it(@"passes the error to the connection block", ^{ waitUntil(^(DoneCallback done) {
                [connectionManager connectWithTimeout:0 usingBlock:^(NSError * anError){
                    expect(anError).to.equal(error);
                    done();
                }];
                [connectionManager didFailToConnect:error];
            });});
            
        });
        
    });

    describe(@"#didConnect", ^{
    
        context(@"when the connection manager is not connecting", ^{
        
            it(@"raises an exception", ^{
                expect(^{
                    [connectionManager didConnect];
                }).to.raise(@"NSInternalInconsistencyException");
            });
            
        });
        
        context(@"when the connection manager is connecting", ^{
        
            it(@"changes the connecting attribute", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                expect(connectionManager.connecting).to.beTruthy;
                [connectionManager didConnect];
                expect(connectionManager.connecting).to.beFalsy;
            });
            
            it(@"changes the connected attribute", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                expect(connectionManager.connecting).to.beFalsy;
                [connectionManager didConnect];
                expect(connectionManager.connecting).to.beTruthy;
            });
            
            it(@"notifies about the established connection", ^{ waitUntil(^(DoneCallback done) {
                id observer = [notificationCenter addObserverForName:WLXBluetoothDeviceConnectionEstablished
                                                              object:connectionManager
                                                               queue:nil
                                                          usingBlock:^(NSNotification * note) {
                                                              expect(note.userInfo[WLXBluetoothDevicePeripheral]).to.equal(mockPeripheral);
                                                              expect(note.userInfo[WLXBluetoothDeviceServicesManager]).to.beInstanceOf([WLXServicesManager class]);
                                                              [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                                              done();
                                                          }];
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [connectionManager didConnect];
            });});
            
            it(@"invokes the delegate's connectionManagerDidConnect", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [connectionManager didConnect];
                [MKTVerify(connectionManagerDelegate) connectionManagerDidConnect:connectionManager];
            });
            
            it(@"calls the connection block", ^{ waitUntil(^(DoneCallback done) {
                [connectionManager connectWithTimeout:0 usingBlock:^(NSError * error){
                    expect(error).to.beNil;
                    done();
                }];
                [connectionManager didConnect];
            });});
            
        });
        
        context(@"when the connection manager is reconecting", ^{
            
            beforeEach(^{
                NSError * error = [NSError errorWithDomain:@"ar.com.wolox.WLXBluetoothDevice.Test" code:0 userInfo:nil];
                id<WLXReconnectionStrategy> rs = [[WLXLinearReconnectionStrategy alloc] initWithWaitTime:0
                                                                                 maxReconnectionAttempts:10
                                                                                       connectionTimeout:0
                                                                                                   queue:queue];
                connectionManager = [[WLXBluetoothConnectionManager alloc] initWithPeripheral:mockPeripheral
                                                                               centralManager:mockCentralManager
                                                                           notificationCenter:notificationCenter
                                                                                        queue:queue
                                                                         reconnectionStrategy:rs
                                                                                   bluetoohOn:NO];
                connectionManager.delegate = connectionManagerDelegate;
                [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOn object:nil userInfo:nil];
                [MKTGiven([mockReconnectionStrategy remainingConnectionAttempts]) willReturnUnsignedInteger:1];
                [MKTGiven([mockReconnectionStrategy connectionTimeout]) willReturnUnsignedInteger:0];
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [connectionManager didConnect];
                [connectionManager didDisconnect:error];
                // This simulates the reconnection executed by the mock reconnection strategy
                [connectionManager connectWithTimeout:0 usingBlock:nil];
            });
            
            it(@"invokes the delegate's connectionManagerDidReconnect:", ^{
                [connectionManager didConnect];
                [MKTVerify(connectionManagerDelegate) connecitonManagerDidReconnect:connectionManager];
            });
            
            it(@"changes the connecting attribute", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                expect(connectionManager.connecting).to.beTruthy;
                [connectionManager didConnect];
                expect(connectionManager.connecting).to.beFalsy;
            });
            
            it(@"changes the connected attribute", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                expect(connectionManager.connecting).to.beFalsy;
                [connectionManager didConnect];
                expect(connectionManager.connecting).to.beTruthy;
            });
            
            it(@"changes the reconnecting attribute", ^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                expect(connectionManager.reconnecting).to.beTruthy;
                [connectionManager didConnect];
                expect(connectionManager.reconnecting).to.beFalsy;
            });
            
            it(@"notifies about the established connection", ^{ waitUntil(^(DoneCallback done) {
                id observer = [notificationCenter addObserverForName:WLXBluetoothDeviceReconnectionEstablished
                                                              object:connectionManager
                                                               queue:nil
                                                          usingBlock:^(NSNotification * note) {
                                                              expect(note.userInfo[WLXBluetoothDevicePeripheral]).to.equal(mockPeripheral);
                                                              expect(note.userInfo[WLXBluetoothDeviceServicesManager]).to.beInstanceOf([WLXServicesManager class]);
                                                              [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                                              done();
                                                          }];
                [connectionManager didConnect];
                
            });});
            
        });
        
    });

    describe(@"#didDisconnect:", ^{
        
        context(@"when the connection manager is connected", ^{
        
            beforeEach(^{
                [connectionManager connectWithTimeout:0 usingBlock:nil];
                [connectionManager didConnect];
            });
            
            context(@"when the disconnect method was called", ^{
            
                beforeEach(^{
                    [connectionManager disconnect];
                });
                
                it(@"changes the connected attribute", ^{
                    expect(connectionManager.connected).to.beTruthy;
                    [connectionManager didDisconnect:nil];
                    expect(connectionManager.connected).to.beFalsy;
                });
                
                it(@"notifies about the connection being terminated", ^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    NSNotification * notification = [NSNotification notificationWithName:WLXBluetoothDeviceConnectionTerminated
                                                                                  object:connectionManager
                                                                                userInfo:userInfo];
                    expect(^{ [connectionManager didDisconnect:nil]; }).to.notify(notification);
                });
                
                it(@"invokes the delegate's connectionManagerDidTerminateConnection: method", ^{
                    [connectionManager didDisconnect:nil];
                    [MKTVerify(connectionManagerDelegate) connectionManagerDidTerminateConnection:connectionManager];
                });
                
                context(@"when an error is given", ^{
                
                    __block NSError * error;
                    
                    beforeEach(^{
                        error = [NSError errorWithDomain:@"ar.com.wolox.WLXBluetoothDevice.ErrorTest" code:0 userInfo:nil];
                    });
                    
                    afterEach(^{
                        error = nil;
                    });
                    
                    it(@"raises an exception", ^{
                        expect(^{
                            int a = 2 + 2;
                            a++;
                            [connectionManager didDisconnect:error];
                        }).to.raise(@"NSInternalInconsistencyException");
                    });
                    
                });
                
            });
            
            context(@"when the disconnect method was not called", ^{
                
                __block NSError * error;
                __block MKTArgumentCaptor * connectionBlockCaptor;
                
                beforeEach(^{
                    connectionBlockCaptor = [[MKTArgumentCaptor alloc] init];
                    error = [NSError errorWithDomain:@"ar.com.wolox.WLXBluetoothDevice.ErrorTest" code:0 userInfo:nil];
                });
                
                afterEach(^{
                    error = nil;
                    connectionBlockCaptor = nil;
                });
            
                context(@"when reconnection is not allowed", ^{
                    
                    beforeEach(^{
                        [[MKTGiven([mockReconnectionStrategy tryToReconnectUsingConnectionBlock:^{}]) withMatcher:anything()] willReturnBool:YES];
                        connectionManager.allowReconnection = NO;
                    });
                    
                    it(@"changes the connected attribute", ^{
                        expect(connectionManager.connected).to.beTruthy;
                        [connectionManager didDisconnect:error];
                        expect(connectionManager.connected).to.beFalsy;
                    });
                    
                    it(@"notifies about the connection being terminated", ^{
                        NSDictionary * userInfo = @{
                                                    WLXBluetoothDevicePeripheral : mockPeripheral,
                                                    WLXBluetoothDeviceError : error
                                                    };
                        NSNotification * notification = [NSNotification notificationWithName:WLXBluetoothDeviceConnectionLost
                                                                                      object:connectionManager
                                                                                    userInfo:userInfo];
                        expect(^{
                            [connectionManager didDisconnect:error];
                        }).to.notify(notification);
                    });
                    
                    it(@"invokes the delegate's connectionManager:didLostConnection:", ^{
                        [connectionManager didDisconnect:error];
                        [MKTVerify(connectionManagerDelegate) connectionManager:connectionManager didLostConnection:error];
                    });
                    
                    
                });
                
                context(@"when there still are reconnection attemps left", ^{
                
                    beforeEach(^{
                        [[MKTGiven([mockReconnectionStrategy tryToReconnectUsingConnectionBlock:^{}]) withMatcher:anything()] willReturnBool:YES];
                        [MKTGiven([mockReconnectionStrategy remainingConnectionAttempts]) willReturnUnsignedInteger:1];
                        [MKTGiven([mockReconnectionStrategy connectionTimeout]) willReturnUnsignedInteger:0];
                    });
                    
                    it(@"changes the connected attribute", ^{
                        expect(connectionManager.connected).to.beTruthy;
                        [connectionManager didDisconnect:error];
                        expect(connectionManager.connected).to.beFalsy;
                    });
                    
                    it(@"tells the central to connect again with the peripheral", ^{
                        [connectionManager didDisconnect:error];
                        [MKTVerify(mockReconnectionStrategy) tryToReconnectUsingConnectionBlock:connectionBlockCaptor.capture];
                        void (^connectionBlock)() = connectionBlockCaptor.value;
                        connectionBlock();
                        [MKTVerifyCount(mockCentralManager, times(2)) connectPeripheral:mockPeripheral options:connectionManager.connectionOptions];
                    });
                    
                    it(@"notifies about the reconnection", ^{
                        NSDictionary * userInfo = @{
                            WLXBluetoothDeviceRemainingReconnectionAttemps : @(1)
                        };
                        NSNotification * notification = [[NSNotification alloc] initWithName:WLXBluetoothDeviceReconnecting
                                                                                      object:connectionManager
                                                                                    userInfo:userInfo];
                        expect(^{ [connectionManager didDisconnect:error]; }).notify(notification);
                    });
                    
                    it(@"invokes the delegate's connectionManager:willAttemptToReconnect: method", ^{
                        [connectionManager didDisconnect:error];
                        [MKTVerify(connectionManagerDelegate) connectionManager:connectionManager willAttemptToReconnect:1];
                    });
                    
                });
                
                context(@"when there are no reconnection attemps left", ^{
                    
                    
                    beforeEach(^{
                        [[MKTGiven([mockReconnectionStrategy tryToReconnectUsingConnectionBlock:^{}]) withMatcher:anything()] willReturnBool:NO];
                    });
                
                    it(@"changes the connected attribute", ^{
                        expect(connectionManager.connected).to.beTruthy;
                        [connectionManager didDisconnect:error];
                        expect(connectionManager.connected).to.beFalsy;
                    });
                    
                    it(@"notifies about the connection being terminated", ^{
                        NSDictionary * userInfo = @{
                            WLXBluetoothDevicePeripheral : mockPeripheral,
                            WLXBluetoothDeviceError : error
                        };
                        NSNotification * notification = [NSNotification notificationWithName:WLXBluetoothDeviceConnectionLost
                                                                                      object:connectionManager
                                                                                    userInfo:userInfo];
                        expect(^{
                            [connectionManager didDisconnect:error];
                        }).to.notify(notification);
                    });
                    
                    it(@"invokes the delegate's connectionManager:didLostConnection:", ^{
                        [connectionManager didDisconnect:error];
                        [MKTVerify(connectionManagerDelegate) connectionManager:connectionManager didLostConnection:error];
                    });
                    
                });
                
            });
            
            
        });
        
    });


SpecEnd