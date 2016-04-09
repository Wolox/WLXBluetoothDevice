//
//  WLXBluetoothDevice.h
//  Pods
//
//  Created by Guido Marucci Blas on 12/19/14.
//
//

#ifndef _WLXBluetoothDevice_
#define _WLXBluetoothDevice_

#import <WLXBluetoothDevice/WLXBluetoothDeviceConnectionError.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceConnectionRecord.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceHelpers.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceLogger.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceManager.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceRegistry.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceUserDefaultsRepository.h>
#import <WLXBluetoothDevice/WLXConnectionManager.h>
#import <WLXBluetoothDevice/WLXDeviceDiscoverer.h>
#import <WLXBluetoothDevice/WLXDeviceDiscovererDelegate.h>
#import <WLXBluetoothDevice/WLXDateProvider.h>
#import <WLXBluetoothDevice/WLXLinearReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXNullReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXReconnectionStrategy.h>
#import <WLXBluetoothDevice/WLXServiceManager.h>
#import <WLXBluetoothDevice/WLXServicesManager.h>

#import <WLXBluetoothDevice/WLXCharacteristicAsyncExecutor.h>

//! Project version number for WLXBluetoothDevice.
FOUNDATION_EXPORT double WLXBluetoothDeviceVersionNumber;

//! Project version string for WLXBluetoothDevice.
FOUNDATION_EXPORT const unsigned char WLXBluetoothDeviceVersionString[];

#endif
