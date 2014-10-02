//
//  WLXBluetoothDeviceRepository.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import <Foundation/Foundation.h>
#import "WLXBluetoothDeviceConnectionRecord.h"

@protocol WLXBluetoothDeviceRepository <NSObject>

- (WLXBluetoothDeviceConnectionRecord *)fetchLastConnectionRecord;

- (BOOL)saveConnectionRecord:(WLXBluetoothDeviceConnectionRecord *)connectionRercord;

@end
