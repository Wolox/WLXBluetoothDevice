//
//  WLXBluetoothDeviceLogger.m
//  Pods
//
//  Created by Guido Marucci Blas on 12/22/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXBluetoothDeviceLogger.h"

@implementation WLXBluetoothDeviceLogger

+ (void)setLogLevel:(int)logLevel {
    for (Class clazz in [DDLog registeredClasses]) {
        [DDLog setLevel:logLevel forClass:clazz];
    }
}

@end
