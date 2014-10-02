//
//  WLXBluetoothDeviceConnectionError.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/1/14.
//
//

#import "WLXBluetoothDeviceConnectionError.h"

NSString * const WLXBluetoothDeviceConnectionErrorDomain = @"ar.com.wolox.BluetoothDevice.ConnectionErrorDomain";

NSError * WLXAlreadyConnectedError() {
    return [NSError errorWithDomain:WLXBluetoothDeviceConnectionErrorDomain
                               code:WLXBluetoothDeviceConnectionErrorAlreadyConnected
                           userInfo:nil];
}

NSError * WLXConnectionAlreadyStartedError() {
    return [NSError errorWithDomain:WLXBluetoothDeviceConnectionErrorDomain
                               code:WLXBluetoothDeviceConnectionErrorConnectionAlreadyStarted
                           userInfo:nil];
}

NSError * WLXBluetoothNotAvailableError() {
    return [NSError errorWithDomain:WLXBluetoothDeviceConnectionErrorDomain
                               code:WLXBluetoothDeviceConnectionErrorBluetoothNotAvailable
                           userInfo:nil];
}

NSError * WLXLastConnectedPeripheralNotAvailableError() {
    return [NSError errorWithDomain:WLXBluetoothDeviceConnectionErrorDomain
                               code:WLXBluetoothDeviceConnectionErrorLastConnectedDeviceNotAvailable
                           userInfo:nil];
}