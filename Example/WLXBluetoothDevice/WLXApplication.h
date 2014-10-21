//
//  WLXApplication.h
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXBluetoothDeviceManager.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceRegistry.h>

@interface WLXApplication : NSObject

@property (nonatomic, readonly) WLXBluetoothDeviceManager * bluetoothDeviceManager;
@property (nonatomic, readonly) WLXBluetoothDeviceRegistry * bluetoothDeviceRegistry;

+ (instancetype)sharedInstance;

@end
