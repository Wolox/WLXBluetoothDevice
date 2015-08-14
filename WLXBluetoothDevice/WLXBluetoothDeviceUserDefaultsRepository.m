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

- (void)deleteConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord withBlock:(void(^)(NSError *))block {
    WLXLogDebug(@"Deleting connection record %@ in user defaults %@", connectionRecord, self.userDefaults);
    [self fetchConnectionRecordsWithBlock:^(NSError * error, NSArray * records) {
        if (error && block) {
            block(error);
        } else {
            NSArray * newRecords = [self removeConnectionRecord:connectionRecord fromRecords:records];
            if (newRecords == records) {
                block(nil);
                return;
            }
            
            NSError * error = [self saveConnectionRecods:newRecords];
            if (error && block) {
                block(error);
            } else if (block) {
                block(nil);
            }
        }
    }];
}

- (void)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord withBlock:(void(^)(NSError *))block {
    WLXLogDebug(@"Saving connection record %@ in user defaults %@", connectionRecord, self.userDefaults);
    [self fetchConnectionRecordsWithBlock:^(NSError * error, NSArray * records) {
        if (error && block) {
            block(error);
        } else {
            NSArray * newRecords = [self insertConnectionRecord:connectionRecord intoRecords:records];
            NSError * error = [self saveConnectionRecods:newRecords];
            if (error && block) {
                block(error);
            } else if (block) {
                block(nil);
            }
        }
    }];
}

#pragma mark - Private methods

- (NSError *)saveConnectionRecods:(NSArray *)records {
    id encodedObject = [NSKeyedArchiver archivedDataWithRootObject:records];
    [self.userDefaults setObject:encodedObject forKey:WLXBluetoothDeviceConnectionRecords];
    NSError * error;
    if (![self.userDefaults synchronize]) {
        error = [NSError errorWithDomain:WLXBluetoothDeviceUserDefaultsRepositoryError
                                    code:UserDefaultsRepositoryErrorUnableToSynch
                                userInfo:nil];
    }
    return error;
}

- (NSArray *)insertConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord
                         intoRecords:(NSArray *)records {
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

- (NSArray *)removeConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRecord
                         fromRecords:(NSArray *)records {
    NSMutableArray * newRecords = [NSMutableArray arrayWithArray:records];
    [newRecords removeObject:connectionRecord];
    
    if (newRecords.count == records.count) {
        return records;
    } else {
        return [NSArray arrayWithArray:newRecords];
    }
}

@end
