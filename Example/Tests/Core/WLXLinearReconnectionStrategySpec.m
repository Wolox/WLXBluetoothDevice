//
//  WLXLinearReconnectionStrategySpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/1/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WLXBluetoothDevice/WLXLinearReconnectionStrategy.h>

SpecBegin(WLXLinearReconnectionStrategySpec)

    __block WLXLinearReconnectionStrategy * reconnectionStrategy;

    beforeEach(^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        reconnectionStrategy = [[WLXLinearReconnectionStrategy alloc] initWithWaitTime:500
                                                               maxReconnectionAttempts:1
                                                                     connectionTimeout:0
                                                                                 queue:queue];
    });

    afterEach(^{
        reconnectionStrategy = nil;
    });

    describe(@"#tryToReconnectUsingConnectionBlock:", ^{
    
        it(@"does not accept a nil connection block", ^{
            expect(^{
                [reconnectionStrategy tryToReconnectUsingConnectionBlock:nil];
            }).to.raiseWithReason(@"NSInternalInconsistencyException", @"block cannot be nil");
        });
        
        context(@"when there still are reconnection attemps", ^{
        
            it(@"tries to reconnect", ^{
                expect([reconnectionStrategy tryToReconnectUsingConnectionBlock:^{}]).to.beTruthy;
            });
            
            it(@"call the connection block after the wait time", ^{
                __block BOOL blockCalled = NO;
                [reconnectionStrategy tryToReconnectUsingConnectionBlock:^{ blockCalled = YES; }];
                expect(blockCalled).after(reconnectionStrategy.waitTime / 1000.0).to.beTruthy;
            });
            
            it(@"decreses the remaining reconnection attemps counter", ^{
                NSUInteger remainingConnectionAttemps = reconnectionStrategy.remainingConnectionAttempts;
                [reconnectionStrategy tryToReconnectUsingConnectionBlock:^{}];
                expect(reconnectionStrategy.remainingConnectionAttempts).to.equal(remainingConnectionAttemps - 1);
            });
            
        });
        
        context(@"when there are no reconnection attemps left", ^{
        
            beforeEach(^{
                [reconnectionStrategy tryToReconnectUsingConnectionBlock:^{}];
            });
            
            it(@"does not try to reconnect", ^{
                expect([reconnectionStrategy tryToReconnectUsingConnectionBlock:^{}]).to.beFalsy;
            });
            
            it(@"does not call the connection block", ^{
                __block BOOL blockCalled = NO;
                [reconnectionStrategy tryToReconnectUsingConnectionBlock:^{ blockCalled = YES; }];
                expect(blockCalled).after(reconnectionStrategy.waitTime / 1000.0).to.beFalsy;
            });
            
        });
        
    });

SpecEnd