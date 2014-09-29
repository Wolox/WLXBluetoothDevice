//
//  WLXPeripheralDiscoveryData.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/28/14.
//
//

#import "WLXDeviceDiscoveryData.h"

@implementation WLXDeviceDiscoveryData

@dynamic deviceName;
@dynamic deviceUUID;

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                 advertisementData:(NSDictionary *)advertisementData
                              RSSI:(NSNumber *)RSSI {
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _advertisementData = advertisementData;
        _RSSI = RSSI;
    }
    return self;
}

- (NSString *)deviceName {
    return self.peripheral.name;
}

- (NSString *)deviceUUID {
    return self.peripheral.identifier.UUIDString;
}

@end
