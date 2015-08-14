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

NSString * const WLXBluetoothDeviceConnectionRecords = @"ar.com.wolox.WLXBluetoothDevice.ConnectionRecords";
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
    [self fetchConnectionRecordsWithBlock:^(NSError * error, NSArray * records) {
        if (error) {
            block(error, nil);
        } else {
            block(nil, records.firstObject);
        }
    }];
}

- (void)fetchConnectionRecordsWithBlock:(void(^)(NSError *, NSArray *))block {
    WLXAssertNotNil(block);
    WLXLogDebug(@"Fetching connection records from user defaults %@", self.userDefaults);
    NSData * encodedObject = [self.userDefaults objectForKey:WLXBluetoothDeviceConnectionRecords];
    if (encodedObject) {
        NSArray * records = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        block(nil, records);
    } else {
        block(nil, @[]);
    }
}

- (void)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord withBlock:(void(^)(NSError *))block {
    WLXLogDebug(@"Saving connection record %@ in user defaults %@", connectionRercord, self.userDefaults);
    [self fetchConnectionRecordsWithBlock:^(NSError * error, NSArray * records) {
        if (error && block) {
            block(error);
        } else {
            NSArray * newRecords = [self insertConnectionRecord:connectionRercord intoRecods:records];
            id encodedObject = [NSKeyedArchiver archivedDataWithRootObject:newRecords];
            [self.userDefaults setObject:encodedObject forKey:WLXBluetoothDeviceConnectionRecords];
            if (block && [self.userDefaults synchronize]) {
                block(nil);
            } else if (block) {
                NSError * error = [NSError errorWithDomain:WLXBluetoothDeviceUserDefaultsRepositoryError
                                                      code:UserDefaultsRepositoryErrorUnableToSynch
                                                  userInfo:nil];
                block(error);
            }
        }
    }];
}

#pragma mark - Private methods

- (NSArray *)insertConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord
                         intoRecods:(NSArray *)records {
    // Only save the newest record per peripheral UUID
    // Records are sorted from newest to oldest.
    NSMutableArray * newRecords = [NSMutableArray arrayWithCapacity:records.count + 1];
    [newRecords addObject:connectionRecord];
    for (WLXBluetoothDeviceConnectionRecord * record in records) {
        if ([record.UUID isEqualToString:connectionRecord.UUID]) {
            continue;
        }
        [newRecords addObject:record];
    }
    
    return [NSArray arrayWithArray:newRecords];
}

@end
