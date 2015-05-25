//
//  WLXBluetoothDeviceUserDefaultsRepository.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import "WLXBluetoothDeviceUserDefaultsRepository.h"

#import "WLXBluetoothDeviceLogger.h"

NSString * const WLXBluetoothDeviceLastConnectionRecord = @"ar.com.wolox.WLXBluetoothDevice.LastConnectionRecord";

@interface WLXBluetoothDeviceUserDefaultsRepository ()

@property (nonatomic) NSUserDefaults * userDefaults;

@end

@implementation WLXBluetoothDeviceUserDefaultsRepository

DYNAMIC_LOGGER_METHODS

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

- (WLXBluetoothDeviceConnectionRecord *)fetchLastConnectionRecord {
    WLXLogDebug(@"Fetching last connection record from user defaults %@", self.userDefaults);
    NSData * encodedObject = [self.userDefaults objectForKey:WLXBluetoothDeviceLastConnectionRecord];
    return [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
}

- (BOOL)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord {
    WLXLogDebug(@"Saving connection record %@ in user defaults %@", connectionRercord, self.userDefaults);
    id encodedObject = [NSKeyedArchiver archivedDataWithRootObject:connectionRercord];
    [self.userDefaults setObject:encodedObject forKey:WLXBluetoothDeviceLastConnectionRecord];
    [self.userDefaults synchronize];
    return YES;
}


@end
