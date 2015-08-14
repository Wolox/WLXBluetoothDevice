//
//  WLXBluetoothDeviceUserDefaultsRepository.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXBluetoothDeviceRepository.h"

extern NSString * const WLXBluetoothDeviceConnectionRecords;
extern NSString * const WLXBluetoothDeviceUserDefaultsRepositoryError;

typedef enum : NSUInteger {
    UserDefaultsRepositoryErrorUnableToSynch
} UserDefaultsRepositoryError;

@interface WLXBluetoothDeviceUserDefaultsRepository : NSObject<WLXBluetoothDeviceRepository>

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults;

@end
