//
//  WLXFakeDateProvider.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/6/14.
//
//

#import "WLXFakeDateProvider.h"

#import "WLXBluetoothDeviceHelpers.h"

@interface WLXFakeDateProvider ()

@property (nonatomic) NSDate * date;

@end

@implementation WLXFakeDateProvider

- (instancetype)initWithDate:(NSDate *)date {
    WLXAssertNotNil(date);
    self = [super init];
    if (self) {
        _date = date;
    }
    return self;
}

- (NSDate *)now {
    return self.date;
}

@end
