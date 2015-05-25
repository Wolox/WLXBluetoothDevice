//
//  WLXConnectionManagerDelegate.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/17/14.
//
//

#import <Foundation/Foundation.h>

@protocol WLXConnectionManager;

@protocol WLXConnectionManagerDelegate <NSObject>

- (void)connectionManagerDidConnect:(id<WLXConnectionManager>)connectionManager;

- (void)connectionManagerDidTerminateConnection:(id<WLXConnectionManager>)connectionManager;

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager didFailToConnect:(NSError *)error;

- (void)connectionManager:(id<WLXConnectionManager>)connectionManager didLostConnection:(NSError *)error;

@optional
- (void)connectionManager:(id<WLXConnectionManager>)connectionManager willAttemptToReconnect:(NSUInteger)remainingReconnectionAttemps;

- (void)connecitonManagerDidReconnect:(id<WLXConnectionManager>)connectionManager;

@end
