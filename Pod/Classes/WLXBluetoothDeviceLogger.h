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


#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WLXBluetoothDeviceLogLevel

#endif
