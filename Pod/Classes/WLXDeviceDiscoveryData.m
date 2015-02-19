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

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }

    if (!object) {
        return NO;
    }

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    WLXDeviceDiscoveryData *deviceData = object;
    return ([deviceData.deviceUUID isEqualToString:self.deviceUUID]);
}

- (NSUInteger)hash {
    return self.deviceUUID.hash;
}

@end
