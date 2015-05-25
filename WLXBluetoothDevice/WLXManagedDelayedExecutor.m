//
//  WLXManagedDelayedExecutor.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/17/14.
//
//

#import "WLXManagedDelayedExecutor.h"

#import "WLXBluetoothDeviceLogger.h"

@interface WLXManagedDelayedExecutor ()

@property (readonly, nonatomic) dispatch_queue_t queue;
@property (readonly, nonatomic) NSMutableSet * executorsTimestamps;

@end

@implementation WLXManagedDelayedExecutor

DYNAMIC_LOGGER_METHODS

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        _executorsTimestamps = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)after:(NSInteger)delay dispatchBlock:(void(^)())block {
    id timestamp = @([NSDate timeIntervalSinceReferenceDate]);
    [self.executorsTimestamps addObject:timestamp];
    WLXLogDebug(@"Enqueueing block with timestamp %@ to be executed in %d ms", timestamp, (int)delay);
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_MSEC));
    dispatch_after(delayTime, self.queue, ^{
        if (![self.executorsTimestamps containsObject:timestamp]) {
            WLXLogVerbose(@"Block with timestamp %@ is not valid anymore", timestamp);
            return;
        }
        [self.executorsTimestamps removeObject:timestamp];
        block();
    });
}

- (void)invalidateExecutors {
    WLXLogVerbose(@"Invalidating all pending executors");
    [self.executorsTimestamps removeAllObjects];
}

@end
