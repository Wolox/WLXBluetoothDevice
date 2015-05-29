//
//  WLXReactiveConnectionManagerDelegate.h
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import <Foundation/Foundation.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <WLXBluetoothDevice/WLXBluetoothDevice.h>

@interface WLXReactiveConnectionManagerDelegate : NSObject<WLXConnectionManagerDelegate>

@property (nonatomic, readonly) RACSignal * connectionEstablished;
@property (nonatomic, readonly) RACSignal * connectionTerminated;
@property (nonatomic, readonly) RACSignal * reconnectionEstablished;
@property (nonatomic, readonly) RACSignal * failToConnect;
@property (nonatomic, readonly) RACSignal * connectionLost;
@property (nonatomic, readonly) RACSignal * reconnectionAttempt;

@end
