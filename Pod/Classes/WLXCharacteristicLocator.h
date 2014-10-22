//
//  WLXCharacteristicLocator.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/22/14.
//
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@protocol WLXCharacteristicLocator <NSObject>

@property (nonatomic, readonly) NSArray * characteristics;

- (CBCharacteristic *)characteristicFromUUID:(CBUUID *)characteristicUUID;

- (void)discoverCharacteristics;

- (void)discoverCharacteristics:(NSArray *)characteristicUUIDs;

@end
