//
//  WLXApplication.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import "WLXApplication.h"

@implementation WLXApplication

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self && ![self isTestMode]) {
        _bluetoothDeviceManager = [WLXBluetoothDeviceManager deviceManager];
        id repository = [[WLXBluetoothDeviceUserDefaultsRepository alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
        _bluetoothDeviceRegistry = [_bluetoothDeviceManager deviceRegistryWithRepository:repository];
    }
    return self;
}

- (BOOL)isTestMode {
    NSDictionary* environment = [[NSProcessInfo processInfo] environment];
    return [environment objectForKey:@"TEST"] != nil;
}

@end
