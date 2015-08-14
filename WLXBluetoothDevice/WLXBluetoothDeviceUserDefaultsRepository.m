//
//  WLXBluetoothDeviceUserDefaultsRepository.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import "WLXBluetoothDeviceUserDefaultsRepository.h"

#import "WLXBluetoothDeviceHelpers.h"
#import "WLXBluetoothDeviceLogger.h"

NSString * const WLXBluetoothDeviceLastConnectionRecord = @"ar.com.wolox.WLXBluetoothDevice.LastConnectionRecord";
NSString * const WLXBluetoothDeviceUserDefaultsRepositoryError = @"ar.com.wolox.WLXBluetoothDevice.UserDefaultsRepository";



@interface WLXBluetoothDeviceUserDefaultsRepository ()

@property (nonatomic) NSUserDefaults * userDefaults;

@end

@implementation WLXBluetoothDeviceUserDefaultsRepository

WLX_BD_DYNAMIC_LOGGER_METHODS

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
    self = [super init];
    if (self) {
        _userDefaults = userDefaults;
    }
    return self;
}

- (void)fetchLastConnectionRecordWithBlock:(void(^)(NSError *, WLXBluetoothDeviceConnectionRecord *))block {
    WLXAssertNotNil(block);
    WLXLogDebug(@"Fetching last connection record from user defaults %@", self.userDefaults);
    NSData * encodedObject = [self.userDefaults objectForKey:WLXBluetoothDeviceLastConnectionRecord];
    WLXBluetoothDeviceConnectionRecord * record = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    block(nil, record);
}

- (void)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord withBlock:(void(^)(NSError *))block {
    WLXLogDebug(@"Saving connection record %@ in user defaults %@", connectionRercord, self.userDefaults);
    id encodedObject = [NSKeyedArchiver archivedDataWithRootObject:connectionRercord];
    [self.userDefaults setObject:encodedObject forKey:WLXBluetoothDeviceLastConnectionRecord];
    if (block && [self.userDefaults synchronize]) {
        block(nil);
    } else if (block) {
        NSError * error = [NSError errorWithDomain:WLXBluetoothDeviceUserDefaultsRepositoryError
                                              code:UserDefaultsRepositoryErrorUnableToSynch
                                          userInfo:nil];
        block(error);
    }
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
