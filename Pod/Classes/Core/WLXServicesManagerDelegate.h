//
//  WLXServicesManagerDelegate.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/21/14.
//
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@protocol WLXServicesManagerDelegate <NSObject>

- (void)didDiscoverCharacteristics;

- (void)failToDiscoverCharacteristics:(NSError *)error;

- (void)didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

- (void)didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

- (void)didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

@end
