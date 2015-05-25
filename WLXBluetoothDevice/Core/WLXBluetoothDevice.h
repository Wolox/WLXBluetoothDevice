//
//  WLXBluetoothDevice.h
//  Pods
//
//  Created by Guido Marucci Blas on 12/19/14.
//
//

#ifndef _WLXBluetoothDevice_
#define _WLXBluetoothDevice_

#import <WLXBluetoothDevice/WLXReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXLinearReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXNullReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>
#import <WLXBluetoothDevice/WLXDeviceDiscoverer.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceManager.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceRegistry.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceUserDefaultsRepository.h>
#import <WLXBluetoothDevice/WLXServicesManager.h>
#import <WLXBluetoothDevice/WLXServiceManager.h>

#import <WLXBluetoothDevice/WLXFakeDateProvider.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceDiscoverer.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceConnectionError.h>
#import <WLXBluetoothDevice/WLXBluetoothConnectionManager.h>

//! Project version number for WLXBluetoothDevice.
FOUNDATION_EXPORT double WLXBluetoothDeviceVersionNumber;

//! Project version string for WLXBluetoothDevice.
FOUNDATION_EXPORT const unsigned char WLXBluetoothDeviceVersionString[];

#endif
