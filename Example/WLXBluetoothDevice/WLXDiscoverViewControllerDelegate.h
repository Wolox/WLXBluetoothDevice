//
//  WLXDiscoverViewControllerDelegate.h
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/6/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WLXDiscoverViewController;
@class CBPeripheral;

@protocol WLXDiscoverViewControllerDelegate <NSObject>

- (void)discoverViewController:(WLXDiscoverViewController *)viewController didSelectPeripheral:(CBPeripheral *)peripheral;

@end
