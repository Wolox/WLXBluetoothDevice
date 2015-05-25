//
//  WLXReactiveConnectionManagerDelegateSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 3/10/15.
//  Copyright (c) 2015 Guido Marucci Blas. All rights reserved.
//
#import "SpecHelper.h"

SpecBegin(WLXReactiveConnectionManagerDelegate)

__block WLXReactiveConnectionManagerDelegate * delegate;
__block id<WLXConnectionManager> connectionManager;

beforeEach(^{
    connectionManager = mockProtocol(@protocol(WLXConnectionManager));
    delegate = [[WLXReactiveConnectionManagerDelegate alloc] init];
});

describe(@"#connectionEstablished", ^{
    
    context(@"when the connection manager establishes a new connection", ^{
       
        it(@"sends a RACUnit value", ^{ waitUntil(^(DoneCallback done) {
            [delegate.connectionEstablished subscribeNext:^(id x) {
               done();
            }];
            [delegate connectionManagerDidConnect:connectionManager];
        });});
        
    });
    
});

describe(@"#connectionTerminated", ^{
    
    context(@"when the connection manager terminates a connections", ^{
       
        it(@"sends a RACUnit value", ^{ waitUntil(^(DoneCallback done) {
            [delegate.connectionTerminated subscribeNext:^(id x) {
                done();
            }];
            [delegate connectionManagerDidTerminateConnection:connectionManager];
        });});
        
    });
    
});

describe(@"#reconnectionEstablished", ^{
    
    context(@"when the connection manager reconnects", ^{
       
        it(@"sends a RACUnit value", ^{ waitUntil(^(DoneCallback done) {
            [delegate.reconnectionEstablished subscribeNext:^(id x) {
                done();
            }];
            [delegate connecitonManagerDidReconnect:connectionManager];
        });});
        
    });
    
});

describe(@"#failToConnect", ^{
    
    context(@"when the connection manager fails to connect", ^{
       
        __block NSError * error;
        
        beforeEach(^{
            error = mock([NSError class]);
        });
        
        it(@"sends the error", ^{ waitUntil(^(DoneCallback done) {
            [delegate.failToConnect subscribeNext:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            [delegate connectionManager:connectionManager didFailToConnect:error];
        });});
        
    });
    
});

describe(@"#connectionLost", ^{
    
    context(@"when the connection is lost", ^{
        
        __block NSError * error;
        
        beforeEach(^{
            error = mock([NSError class]);
        });
        
        it(@"sends the error", ^{ waitUntil(^(DoneCallback done) {
            [delegate.connectionLost subscribeNext:^(NSError * anError) {
                expect(anError).to.equal(error);
                done();
            }];
            [delegate connectionManager:connectionManager didLostConnection:error];
        });});
        
    });
    
});

describe(@"#reconnectionAttempt", ^{
    
    context(@"when the connection manager will attempt to reconnect", ^{
       
        __block NSUInteger remainingReconnectionAttemps;
        
        beforeEach(^{
            remainingReconnectionAttemps = 2;
        });
        
        it(@"sends the remaining reconnection attemps", ^{ waitUntil(^(DoneCallback done) {
            [delegate.reconnectionAttempt subscribeNext:^(NSNumber * remaining) {
                expect(remaining.unsignedIntegerValue).to.equal(remainingReconnectionAttemps);
                done();
            }];
            [delegate connectionManager:connectionManager willAttemptToReconnect:remainingReconnectionAttemps];
        });});
        
    });
    
});

SpecEnd