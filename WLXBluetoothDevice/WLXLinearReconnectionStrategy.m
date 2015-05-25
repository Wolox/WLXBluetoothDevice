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

@interface WLXLinearReconnectionStrategy ()

@property (nonatomic) dispatch_queue_t queue;

@end

@implementation WLXLinearReconnectionStrategy

DYNAMIC_LOGGER_METHODS

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
    }
    return self;
}

- (BOOL)tryToReconnectUsingConnectionBlock:(void(^)())block {
    WLXAssertNotNil(block);
    if (_remainingConnectionAttempts-- <= 0) {
        return NO;
    }
    WLXLogDebug(@"Waiting for %d ms before trying to reconnect", (int)_waitTime);
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.waitTime * NSEC_PER_MSEC));
    dispatch_after(delayTime, self.queue, ^{
        WLXLogDebug(@"Trying to reconnect with device. Remaining reconnection attempts %d. Max reconnection attempts %d",
                   (int)_remainingConnectionAttempts, (int)_maxReconnectionAttempts);
        block();
    });
    return YES;
}

- (void)reset {
    _remainingConnectionAttempts = _maxReconnectionAttempts;
}



@end
