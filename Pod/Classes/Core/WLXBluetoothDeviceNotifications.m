//
//  WLXBluetoothDeviceNotifications.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#import "WLXBluetoothDeviceNotifications.h"

// Bluetooth related notifications
NSString * const WLXBluetoothDeviceBluetoothIsOn = @"ar.com.wolox.WLXBluetoothDevice.BluetoothIsOn";
NSString * const WLXBluetoothDeviceBluetoothIsOff = @"ar.com.wolox.WLXBluetoothDevice.BluetoothIsOff";
NSString * const WLXBluetoothDeviceBluetoothPowerStatusChanged = @"ar.com.wolox.WLXBluetoothDevice.PowerStatusChanged";

// Discovering related notifications
NSString * const WLXBluetoothDeviceStartDiscovering = @"ar.com.wolox.WLXBluetoothDevice.StartDiscovering";
NSString * const WLXBluetoothDeviceStoptDiscovering = @"ar.com.wolox.WLXBluetoothDevice.StopDiscovering";
NSString * const WLXBluetoothDeviceDeviceDiscovered = @"ar.com.wolox.WLXBluetoothDevice.DeviceDiscovered";

// Connection related notifications
NSString * const WLXBluetoothDeviceConnectionEstablished = @"ar.com.wolox.WLXBluetoothDevice.ConnectionEstablished";
NSString * const WLXBluetoothDeviceReconnectionEstablished = @"ar.com.wolox.WLXBluetoothDevice.ReconnectionEstablished";
NSString * const WLXBluetoothDeviceFailToConnect = @"ar.com.wolox.WLXBluetoothDevice.FailToConnect";
NSString * const WLXBluetoothDeviceConnectionLost = @"ar.com.wolox.WLXBluetoothDevice.ConnectionLost";
NSString * const WLXBluetoothDeviceConnectionTerminated = @"ar.com.wolox.WLXBluetoothDevice.ConnectionTerminated";
NSString * const WLXBluetoothDeviceReconnecting = @"ar.com.wolox.WLXBluetoothDevice.Reconnecting";

// User info keys
NSString * const WLXBluetoothDeviceDiscoveryData = @"ar.com.wolox.WLXBluetoothDevice.UserInfo.DiscoveryData";
NSString * const WLXBluetoothDevicePeripheral = @"ar.com.wolox.WLXBluetoothDevice.UserInfo.Peripheral";
NSString * const WLXBluetoothDeviceError = @"ar.com.wolox.WLXBluetoothDevice.UserInfo.Error";
NSString * const WLXBluetoothDeviceRemainingReconnectionAttemps = @"ar.com.wolox.WLXBluetoothDevice.UserInfo.RemainingReconnectionAttemps";
NSString * const WLXBluetoothEnabled = @"ar.com.wolox.WLXBluetoothDevice.UserInfo.BluetoothEnabled";
NSString * const WLXBluetoothDeviceServicesManager = @"ar.com.wolox.WLXBluetoothDevice.UserInfo.ServicesManager";