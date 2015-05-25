//
//  WLXConnectionManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/5/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXConnectionManagerDelegate.h"
#import "WLXServicesManager.h"

@import CoreBluetooth;

@protocol WLXConnectionManager <NSObject>

@property (nonatomic, readonly, getter=isReconnecting) BOOL reconnecting;
@property (nonatomic, readonly, getter=isActive) BOOL active;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;
@property (nonatomic, readonly) CBPeripheral * peripheral;
@property (nonatomic, readonly) NSString * peripheralUUID;
@property (nonatomic) NSDictionary * connectionOptions;
@property (nonatomic, weak) id<WLXConnectionManagerDelegate> delegate;
@property (nonatomic, readonly) WLXServicesManager * servicesManager;
@property (nonatomic) BOOL allowReconnection;

- (BOOL)connectWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block ;

- (BOOL)connectWithTimeout:(NSUInteger)timeout;

- (BOOL)connectAndDiscoverServicesWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block;

- (void)disconnect;

@end
