//
//  WLXServiceManager+RACSignalSupport.h
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <WLXBluetoothDevice/WLXBluetoothDevice.h>

@interface WLXServiceManager (RACSignalSupport)

#pragma mark - Reading & writing characteristic value

- (RACSignal *)rac_readValueFromCharacteristic:(CBUUID *)characteristicUUID;

- (RACSignal *)rac_writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID;

#pragma mark - Handling characteristic notifications

- (RACSignal *)rac_enableNotificationsForCharacteristic:(CBUUID *)characteristicUUID;

- (RACSignal *)rac_disableNotificationsForCharacteristic:(CBUUID *)characteristicUUID;

- (RACSignal *)rac_notificationsForCharacteristic:(CBUUID *)characteristicUUID;

@end
