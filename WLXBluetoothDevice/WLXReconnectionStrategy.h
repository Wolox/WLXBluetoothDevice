//
//  WLXReconnectionStrategy.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/1/14.
//
//

#import <Foundation/Foundation.h>

@protocol WLXReconnectionStrategy <NSObject>

@property (nonatomic, readonly) NSUInteger maxReconnectionAttempts;
@property (nonatomic, readonly) NSUInteger remainingConnectionAttempts;
@property (nonatomic, readonly) NSUInteger connectionTimeout;

- (BOOL)tryToReconnectUsingConnectionBlock:(void(^)())block;

- (void)reset;

@end
