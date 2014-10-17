//
//  WLXNullReconnectionStrategy.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/6/14.
//
//

#import "WLXNullReconnectionStrategy.h"

@implementation WLXNullReconnectionStrategy

@synthesize remainingConnectionAttempts;
@synthesize maxReconnectionAttempts;
@synthesize connectionTimeout;

- (BOOL)tryToReconnectUsingConnectionBlock:(void (^)())block {
    return NO;
}

- (NSUInteger)remainingConnectionAttempts {
    return 0;
}

- (NSUInteger)maxReconnectionAttempts {
    return 0;
}

- (NSUInteger)connectionTimeout {
    return 0;
}

- (void)reset {
}

@end
