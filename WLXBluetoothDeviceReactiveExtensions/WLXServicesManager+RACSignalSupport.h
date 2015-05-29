//
//  WLXServicesManager+RACSignalSupport.h
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import <Foundation/Foundation.h>
#import <WLXBluetoothDevice/WLXBluetoothDevice.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface WLXServicesManager (RACSignalSupport)

- (RACSignal *)rac_discoverServices;

@end
