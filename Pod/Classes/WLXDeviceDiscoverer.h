//
//  WLXDeviceDiscoverer.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/5/14.
//
//

#import <Foundation/Foundation.h>

@protocol WLXDeviceDiscoverer <NSObject>

@property (getter=isDiscovering) BOOL discovering;
@property (nonatomic, readonly) NSArray * discoveredDevices;
@property (nonatomic) NSDictionary * scanOptions;

- (BOOL)discoverDevicesNamed:(NSString *)nameRegex withServices:(NSArray *)servicesUUIDs andTimeout:(NSUInteger)timeout;

- (void)stopDiscoveringDevices;

@end
