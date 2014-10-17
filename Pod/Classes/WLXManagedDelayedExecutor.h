//
//  WLXManagedDelayedExecutor.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/17/14.
//
//

#import <Foundation/Foundation.h>

@interface WLXManagedDelayedExecutor : NSObject

- (instancetype)initWithQueue:(dispatch_queue_t)queue;

- (void)after:(NSInteger)delay dispatchBlock:(void(^)())block;

- (void)invalidateExecutors;

@end
