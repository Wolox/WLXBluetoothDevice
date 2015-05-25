//
//  WLXServicesManager+RACSignalSupport.m
//  Pods
//
//  Created by Guido Marucci Blas on 3/10/15.
//
//

#import "WLXServicesManager+RACSignalSupport.h"

@implementation WLXServicesManager (RACSignalSupport)

- (RACSignal *)rac_discoverServices {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self discoverServicesUsingBlock:^(NSError * error) {
            if (error) {
                [subscriber sendError:error];
            } else {
                [subscriber sendCompleted];
            }
        }];
        return nil;
    }] replayLazily];
}


@end
