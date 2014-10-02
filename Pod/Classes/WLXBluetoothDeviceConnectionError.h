//
//  WLXBluetoothDeviceConnectionError.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/1/14.
//
//

#import <Foundation/Foundation.h>

extern NSString * const WLXBluetoothDeviceConnectionErrorDomain;
typedef enum : NSUInteger {
    WLXBluetoothDeviceConnectionErrorConnectionAlreadyStarted,
    WLXBluetoothDeviceConnectionErrorAlreadyConnected,
    WLXBluetoothDeviceConnectionErrorConnectionTimeoutExpired,
    WLXBluetoothDeviceConnectionErrorBluetoothNotAvailable,
    WLXBluetoothDeviceConnectionErrorLastConnectedDeviceNotAvailable
} WLXBluetoothDeviceConnectionError;

NSError * WLXAlreadyConnectedError();

NSError * WLXConnectionAlreadyStartedError();

NSError * WLXBluetoothNotAvailableError();

NSError * WLXLastConnectedPeripheralNotAvailableError();