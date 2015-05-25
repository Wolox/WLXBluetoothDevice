//
//  WLXBluetoothConnectionManager.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXConnectionManager.h"
#import "WLXBluetoothDeviceRepository.h"
#import "WLXReconnectionStrategy.h"

@import CoreBluetooth;

@interface WLXBluetoothConnectionManager : NSObject<WLXConnectionManager>

@property (nonatomic, readonly, getter=isBluetoothOn) BOOL bluetoothOn;
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

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                    centralManager:(CBCentralManager *)centralManager
                notificationCenter:(NSNotificationCenter *)notificationCenter
                             queue:(dispatch_queue_t)queue
              reconnectionStrategy:(id<WLXReconnectionStrategy>)reconnectionStrategy
                        bluetoohOn:(BOOL)bluetoothOn;

- (void)didFailToConnect:(NSError *)error;

- (void)didDisconnect:(NSError *)error;

- (void)didConnect;

@end
