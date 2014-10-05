//
//  WLXConnectionManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/5/14.
//
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@protocol WLXConnectionManager <NSObject>

@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;
@property (nonatomic, readonly) CBPeripheral * peripheral;
@property (nonatomic, readonly) NSString * peripheralUUID;
@property (nonatomic) NSDictionary * connectionOptions;

- (BOOL)connectWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block ;

- (void)disconnect;

@end
