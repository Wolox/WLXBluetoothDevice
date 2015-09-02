//
//  WLXBluetoothDeviceConnectionRecord.m
//  Pods
//
//  Created by Guido Marucci Blas on 9/30/14.
//
//

#import "WLXBluetoothDeviceConnectionRecord.h"
#import "WLXBluetoothDeviceHelpers.h"
#import "WLXRealDateProvider.h"

static id<WLXDateProvider> dateProvider;

@implementation WLXBluetoothDeviceConnectionRecord

+ (void)initialize {
    dateProvider = [[WLXRealDateProvider alloc] init];
}

+ (void)setDateProvider:(id<WLXDateProvider>)aDateProvider {
    WLXAssertNotNil(aDateProvider);
    dateProvider = aDateProvider;
}

+ (instancetype)recordWithPeripheral:(CBPeripheral *)peripheral {
    return [[WLXBluetoothDeviceConnectionRecord alloc] initWithPeripheral:peripheral connectionDate:[dateProvider now]];
}

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral connectionDate:(NSDate *)connectionDate {
    WLXAssertNotNil(peripheral);
    return [self initWithUUID:peripheral.identifier.UUIDString name:peripheral.name connectionDate:connectionDate];
}

- (instancetype)initWithUUID:(NSString *)UUID name:(NSString *)name connectionDate:(NSDate *)connectionDate {
    WLXAssertNotEmpty(UUID);
    WLXAssertNotEmpty(name);
    WLXAssertNotNil(connectionDate);
    self = [super init];
    if (self) {
        _UUID = UUID;
        _name = name;
        _connectionDate = connectionDate;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _UUID = [decoder decodeObjectForKey:@"UUID"];
        _name = [decoder decodeObjectForKey:@"name"];
        _connectionDate = [decoder decodeObjectForKey:@"connectionDate"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:self.connectionDate forKey:@"connectionDate"];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![self isKindOfClass:[other class]]) {
        return NO;
    } else {
        WLXBluetoothDeviceConnectionRecord * otherRecord = other;
        return [self.UUID isEqualToString:otherRecord.UUID] &&
               [self.name isEqualToString:otherRecord.name] &&
               [self.connectionDate isEqualToDate:otherRecord.connectionDate];
    }
}

- (NSUInteger)hash {
    return self.UUID.hash ^ self.name.hash ^ self.connectionDate.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@:%p, UUID:%@ name:%@ connectionDate:%@>",
            NSStringFromClass(self.class), self, self.UUID, self.name, self.connectionDate];
}

- (CBPeripheral *)loadPeripheralFromCentral:(CBCentralManager *)centralManager {
    NSArray * UUIDs = @[[[NSUUID alloc] initWithUUIDString:self.UUID]];
    NSArray * peripherals = [centralManager retrievePeripheralsWithIdentifiers:UUIDs];
    return [peripherals firstObject];
}

@end
