//
//  WLXBluetoothDeviceHelpers.h
//  Pods
//
//  Created by Guido Marucci Blas on 9/29/14.
//
//

#ifndef Pods_WLXBluetoothDeviceHelpers_h
#define Pods_WLXBluetoothDeviceHelpers_h

#define WLXAssertNotNullMessage(variable)                                                           \
    [NSString stringWithFormat:@"%s cannot be NULL", #variable]

#define WLXAssertNotNilMessage(variable)                                                            \
    [NSString stringWithFormat:@"%s cannot be nil", #variable]

#define WLXAssertNotEmptyMessage(variable)                                                          \
    [NSString stringWithFormat:@"%s cannot be empty", #variable]

#define WLXAssertNotNil(variable)                                                                   \
    NSAssert(variable, WLXAssertNotNilMessage(variable))

#define WLXAssertNotEmpty(variable)                                                                 \
    if ([variable respondsToSelector:@selector(count)]) {                                           \
        NSAssert(variable != nil && [(id)variable count] > 0, WLXAssertNotEmptyMessage(variable));  \
    } else if ([variable respondsToSelector:@selector(length)]) {                                   \
        NSAssert(variable != nil && [(id)variable length] > 0, WLXAssertNotEmptyMessage(variable)); \
    } else {                                                                                        \
        WLXAssertNotNil(variable);                                                                  \
    }

#define WLXAssertNotNull(variable)                                                                  \
    NSAssert(variable != NULL, WLXAssertNotNullMessage(variable))                                   


#endif
