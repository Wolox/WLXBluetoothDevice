//
//  WLXBluetoothDeviceNotifications.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#import <Foundation/Foundation.h>

// Bluetooth related notifications
extern NSString * const WLXBluetoothDeviceBluetoothIsOn;
extern NSString * const WLXBluetoothDeviceBluetoothIsOff;
extern NSString * const WLXBluetoothDeviceBluetoothPowerStatusChanged;

// Discovering related notifications
extern NSString * const WLXBluetoothDeviceStartDiscovering;
extern NSString * const WLXBluetoothDeviceStoptDiscovering;
extern NSString * const WLXBluetoothDeviceDeviceDiscovered;

// Connection related notifications
extern NSString * const WLXBluetoothDeviceConnectionEstablished;
extern NSString * const WLXBluetoothDeviceReconnectionEstablished;
extern NSString * const WLXBluetoothDeviceFailToConnect;
extern NSString * const WLXBluetoothDeviceConnectionLost;
extern NSString * const WLXBluetoothDeviceConnectionTerminated;
extern NSString * const WLXBluetoothDeviceReconnecting;

// User info keys
extern NSString * const WLXBluetoothDeviceDiscoveryData;
extern NSString * const WLXBluetoothDevicePeripheral;
extern NSString * const WLXBluetoothDeviceError;
extern NSString * const WLXBluetoothDeviceRemainingReconnectionAttemps;
extern NSString * const WLXBluetoothEnabled;
extern NSString * const WLXBluetoothDeviceServicesManager;