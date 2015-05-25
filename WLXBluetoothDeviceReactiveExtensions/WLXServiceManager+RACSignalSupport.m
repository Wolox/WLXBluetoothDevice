//
//  WLXServiceManager+RACSignalSupport.m
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import "WLXServiceManager+RACSignalSupport.h"

@implementation WLXServiceManager (RACSignalSupport)

#pragma mark - Reading & writing characteristic value

- (RACSignal *)rac_readValueFromCharacteristic:(CBUUID *)characteristicUUID {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self readValueFromCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendNext:data];
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }] replayLast];
}

- (RACSignal *)rac_writeValue:(NSData *)data toCharacteristic:(CBUUID *)characteristicUUID {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self writeValue:data toCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }] replayLast];
}

#pragma mark - Handling characteristic notifications

- (RACSignal *)rac_enableNotificationsForCharacteristic:(CBUUID *)characteristicUUID {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self enableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }] replayLast];
}

- (RACSignal *)rac_disableNotificationsForCharacteristic:(CBUUID *)characteristicUUID {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self disableNotificationsForCharacteristic:characteristicUUID usingBlock:^(NSError * error) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }] replayLast];
}

- (RACSignal *)rac_notificationsForCharacteristic:(CBUUID *)characteristicUUID {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        id observer = [self addObserverForCharacteristic:characteristicUUID usingBlock:^(NSError * error, NSData * data) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendNext:data];
            }
        }];
        return [RACDisposable disposableWithBlock:^{
            [self removeObserver:observer];
        }];
    }];
}

@end
