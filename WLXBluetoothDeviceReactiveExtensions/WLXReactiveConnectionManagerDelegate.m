//
//  WLXReactiveConnectionManagerDelegate.m
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import "WLXReactiveConnectionManagerDelegate.h"

@interface WLXReactiveConnectionManagerDelegate ()

@property (nonatomic, readonly) RACSubject * connectionEstablishedSubject;
@property (nonatomic, readonly) RACSubject * connectionTerminatedSubject;
@property (nonatomic, readonly) RACSubject * reconnectionEstablishedSubject;
@property (nonatomic, readonly) RACSubject * failToConnectSubject;
@property (nonatomic, readonly) RACSubject * connectionLostSubject;
@property (nonatomic, readonly) RACSubject * reconnectionAttemptSubject;

@end

@implementation WLXReactiveConnectionManagerDelegate

@dynamic connectionEstablished;
@dynamic connectionTerminated;
@dynamic reconnectionEstablished;
@dynamic failToConnect;
@dynamic connectionLost;
@dynamic reconnectionAttempt;

- (instancetype)init {
    self = [super init];
    if (self) {
        _connectionEstablishedSubject = [RACSubject subject];
        _connectionTerminatedSubject = [RACSubject subject];
        _reconnectionAttemptSubject = [RACSubject subject];
        _failToConnectSubject = [RACSubject subject];
        _connectionLostSubject = [RACSubject subject];
        _reconnectionEstablishedSubject = [RACSubject subject];
    }
    return self;
}

- (RACSignal *)connectionLost {
    return self.connectionLostSubject;
}

- (RACSignal *)connectionTerminated {
    return self.connectionTerminatedSubject;
}

- (RACSignal *)connectionEstablished {
    return self.connectionEstablishedSubject;
}

- (RACSignal *)failToConnect {
    return self.failToConnectSubject;
}

- (RACSignal *)reconnectionAttempt {
    return self.reconnectionAttemptSubject;
}

- (RACSignal *)reconnectionEstablished {
    return self.reconnectionEstablishedSubject;
}

- (void)connectionManagerDidConnect:(id<WLXConnectionManager>)connectionManager {
    [self.connectionEstablishedSubject sendNext:[RACUnit defaultUnit]];
}

- (void)connectionManagerDidTerminateConnection:(id<WLXConnectionManager>)connectionManager {
    [self.connectionTerminatedSubject sendNext:[RACUnit defaultUnit]];
}

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager didFailToConnect:(NSError *)error {
    [self.failToConnectSubject sendNext:error];
}

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager didLostConnection:(NSError *)error {
    [self.connectionLostSubject sendNext:error];
}

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager
   willAttemptToReconnect:(NSUInteger)remainingReconnectionAttemps {
    [self.reconnectionAttemptSubject sendNext:@(remainingReconnectionAttemps)];
}

- (void)connecitonManagerDidReconnect:(id<WLXConnectionManager>)connectionManager {
    [self.reconnectionEstablishedSubject sendNext:[RACUnit defaultUnit]];
}

@end
