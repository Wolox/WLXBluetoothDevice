//
//  WLXBluetoothDeviceLogger.m
//  Pods
//
//  Created by Guido Marucci Blas on 12/22/14.
//
//

#import <Foundation/Foundation.h>

#import "WLXBluetoothDeviceLogger.h"

@implementation WLXBluetoothDeviceLogger

+ (void)setLogLevel:(DDLogLevel)logLevel {
    SEL loggerContextSelector = NSSelectorFromString(@"loggerContext");
    for (Class clazz in [DDLog registeredClasses]) {
        if (![clazz respondsToSelector:loggerContextSelector]) {
            continue;
        }
        
        // Performs loggerContext method on the given class
        int loggerContext;
        NSMethodSignature * signature = [clazz methodSignatureForSelector:loggerContextSelector];
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:loggerContextSelector];
        [invocation setTarget:clazz];
        [invocation invoke];
        [invocation getReturnValue:&loggerContext];
        
        if (loggerContext == WLX_LOG_CONTEXT) {
            [DDLog setLevel:logLevel forClass:clazz];
        }
    }
}

@end
