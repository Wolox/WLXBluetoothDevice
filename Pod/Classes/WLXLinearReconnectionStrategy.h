//
//  WLXLinearReconnectionStrategy.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/1/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXReconnectionStrategy.h"

@interface WLXLinearReconnectionStrategy : NSObject<WLXReconnectionStrategy>

@property (nonatomic, readonly) NSUInteger waitTime;
@property (nonatomic, readonly) NSUInteger maxReconnectionAttempts;
@property (nonatomic, readonly) NSUInteger remainingConnectionAttempts;
@property (nonatomic, readonly) NSUInteger connectionTimeout;

- (instancetype)initWithWaitTime:(NSUInteger)waitTime
         maxReconnectionAttempts:(NSUInteger)maxReconnectionAttempts
               connectionTimeout:(NSUInteger)connectionTimeout
                           queue:(dispatch_queue_t)queue;

@end
