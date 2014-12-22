//
//  WLXBluetoothDeviceLogger.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#ifndef Pods_WLXBluetoothDeviceLogger_h
#define Pods_WLXBluetoothDeviceLogger_h

#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
static int WLXBluetoothDeviceLogLevel = DDLogLevelVerbose;
#endif
#ifdef RELEASE
static int WLXBluetoothDeviceLogLevel = DDLogLevelWarning;
#endif

#define WLX_LOG_CONTEXT 69569 // WOLOX

#define WLXLogError(frmt, ...) LOG_MAYBE(NO, WLXBluetoothDeviceLogLevel, DDLogFlagError, WLX_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define WLXLogWarn(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, WLXBluetoothDeviceLogLevel, DDLogFlagWarning, WLX_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define WLXLogInfo(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, WLXBluetoothDeviceLogLevel, DDLogFlagInfo, WLX_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define WLXLogDebug(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, WLXBluetoothDeviceLogLevel, DDLogFlagDebug, WLX_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define WLXLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, WLXBluetoothDeviceLogLevel, DDLogFlagVerbose, WLX_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define DYNAMIC_LOGGER_METHODS                  \
    + (int)ddLogLevel {                         \
        return WLXBluetoothDeviceLogLevel;      \
    }                                           \
                                                \
    + (void)ddSetLogLevel:(int)logLevel {       \
        WLXBluetoothDeviceLogLevel = logLevel;  \
    }

#endif

@interface WLXBluetoothDeviceLogger : NSObject

+ (void)setLogLevel:(int)logLevel;

@end