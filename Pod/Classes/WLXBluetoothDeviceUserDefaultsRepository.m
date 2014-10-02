//
//  WLXBluetoothDeviceUserDefaultsRepository.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import "WLXBluetoothDeviceUserDefaultsRepository.h"

NSString * const WLXBluetoothDeviceLastConnectionRecord = @"ar.com.wolox.WLXBluetoothDevice.LastConnectionRecord";

@interface WLXBluetoothDeviceUserDefaultsRepository ()

@property (nonatomic) NSUserDefaults * userDefaults;

@end

@implementation WLXBluetoothDeviceUserDefaultsRepository

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

- (WLXBluetoothDeviceConnectionRecord *)fetchLastConnectionRecord {
    return [self.userDefaults objectForKey:WLXBluetoothDeviceLastConnectionRecord];
}

- (BOOL)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord {
    [self.userDefaults setObject:connectionRercord forKey:WLXBluetoothDeviceLastConnectionRecord];
    return YES;
}


@end
