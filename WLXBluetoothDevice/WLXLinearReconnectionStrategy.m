//
//  WLXLinearReconnectionStrategy.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/1/14.
//
//

#import "WLXLinearReconnectionStrategy.h"
#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceLogger.h"
#import "WLXManagedDelayedExecutor.h"

@interface WLXLinearReconnectionStrategy ()

@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic) WLXManagedDelayedExecutor * delayedExecutor;

@end

@implementation WLXLinearReconnectionStrategy

WLX_BD_DYNAMIC_LOGGER_METHODS

- (instancetype)initWithWaitTime:(NSUInteger)waitTime
         maxReconnectionAttempts:(NSUInteger)maxReconnectionAttempts
               connectionTimeout:(NSUInteger)connectionTimeout
                           queue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _waitTime = waitTime;
        _maxReconnectionAttempts = maxReconnectionAttempts;
        _connectionTimeout = connectionTimeout;
        _remainingConnectionAttempts = maxReconnectionAttempts;
        _queue = queue;
        _delayedExecutor = [[WLXManagedDelayedExecutor alloc] initWithQueue:queue];
    }
    return self;
}

- (BOOL)tryToReconnectUsingConnectionBlock:(void(^)())block {
    WLXAssertNotNil(block);
    if (_remainingConnectionAttempts-- <= 0) {
        return NO;
    }
    WLXLogDebug(@"Waiting for %d ms before trying to reconnect", (int)_waitTime);
    [self.delayedExecutor invalidateExecutors];
    WLXLogDebug(@"Previous reconnection attempts delayed blocks have been invalidated");
    [self.delayedExecutor after:self.waitTime dispatchBlock:^{
        WLXLogDebug(@"Trying to reconnect with device. Remaining reconnection attempts %d. Max reconnection attempts %d",
                    (int)_remainingConnectionAttempts, (int)_maxReconnectionAttempts);
        block();
    }];
    return YES;
}

- (void)reset {
    _remainingConnectionAttempts = _maxReconnectionAttempts;
    [self.delayedExecutor invalidateExecutors];
}



@end
