//
//  WLXBluetoothConnectionManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXBluetoothDeviceRepository.h"
#import "WLXReconnectionStrategy.h"

@import CoreBluetooth;

@interface WLXBluetoothConnectionManager : NSObject

@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic, readonly, getter=isConnecting) BOOL connecting;
@property (nonatomic, readonly) CBPeripheral * peripheral;
@property (nonatomic) NSDictionary * connectionOptions;


- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                    centralManager:(CBCentralManager *)centralManager
                notificationCenter:(NSNotificationCenter *)notificationCenter
                             queue:(dispatch_queue_t)queue
              reconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy;

- (BOOL)connectWithTimeout:(NSUInteger)timeout usingBlock:(void(^)(NSError *))block ;

- (void)disconnect;

- (void)didFailToConnect:(NSError *)error;

- (void)didDisconnect:(NSError *)error;

- (void)didConnect;

@end
