//
//  WLXPeripheralDiscoveryData.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import <Foundation/Foundation.h>

@import CoreBluetooth;

@interface WLXDeviceDiscoveryData : NSObject

@property (nonatomic, readonly) CBPeripheral * peripheral;
@property (nonatomic, readonly) NSDictionary * advertisementData;
@property (nonatomic, readonly) NSNumber * RSSI;
@property (nonatomic, readonly) NSString * deviceName;
@property (nonatomic, readonly) NSString * deviceUUID;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI;

@end
