//
//  WLXFakeDateProvider.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/6/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXDateProvider.h"

@interface WLXFakeDateProvider : NSObject<WLXDateProvider>

- (instancetype)initWithDate:(NSDate *)date;

@end
