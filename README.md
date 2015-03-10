# WLXBluetoothDevice

[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/Wolox/WLXBluetoothDevice?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![CI Status](https://travis-ci.org/Wolox/WLXBluetoothDevice.svg?branch=master)](https://travis-ci.org/Wolox/WLXBluetoothDevice)
[![Coverage Status](https://coveralls.io/repos/Wolox/WLXBluetoothDevice/badge.png?branch=master)](https://coveralls.io/r/Wolox/WLXBluetoothDevice?branch=master)
[![Version](https://img.shields.io/cocoapods/v/WLXBluetoothDevice.svg?style=flat)](http://cocoadocs.org/docsets/WLXBluetoothDevice)
[![License](https://img.shields.io/cocoapods/l/WLXBluetoothDevice.svg?style=flat)](http://cocoadocs.org/docsets/WLXBluetoothDevice)
[![Platform](https://img.shields.io/cocoapods/p/WLXBluetoothDevice.svg?style=flat)](http://cocoadocs.org/docsets/WLXBluetoothDevice)

**WLXBluetoothDevice** is a library we have developed at [Wolox](http://www.wolox.com.ar)
after working in several Bluetooth 4.0 related projects. For those who have used
[CoreBluetooth](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html)
before would know that the API is not the most pleasant to use. The CoreBluetooth API
is heavily based on delegators that have too much responsibility and its
asynchronous nature makes it really easy to end up with spaghetti code.

**WLXBluetoothDevice** is block-based wrapper of CoreBluetooth that handles most of the
boilerplate for you. It was designed with the following goals in mind:

  * Avoid having to deal with complex asynchronous logic spread all over
  several delegate methods.
  * Reduce the amount of ceremony necessary to start exchanging
  data between two devices.
  * Handle all the `CBCentralManagerDelegate` and `CBPeripheralDelegate` methods internally and
  expose a block-based API to the user.
  * Implement common uses cases and patterns that are found in most BLE apps.
  * Provide a clean architecture to build maintainable code on top of it.
  * Facilitate automated testing of Bluetooth dependent code.

Here are some of the most relevant features that are included in **WLXBluetoothDevice**:

  * Connection timeouts
  * Reconnection strategies
  * Block-based API
  * Automatic characteristic discovery
  * NSNotifications for Bluetooth connection and discovery events.
  * Storage service to remember devices.

### Dependencies

We wanted to minimize the use of external dependencies and we commit not to
include any other external library unless that library solves a huge problem.
The only dependency that **WLXBluetoothDevice** has is
[CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack) because
is a great library and you should use it. Also if you need to debug what
is happening with the Bluetooth connection you can turn our logger on and you
will get a lot of information about what the library is doing.

### Future versions

We want version `0.1.0` to be the core base set of features and then build
more cool stuff on top of it. We plan to add a [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)
API as a separate sub spec, so for those who like reactive functional programming there
will be a signal based API.

Once [CocoaPods](http://cocoapods.org/) supports Swift we will add it as a
first class citizen, exposing an API that feels more natural in Swift.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.
To actually use the example app you need a Bluetooth peripheral that exposes certain
characteristics in a certain way. That is why we made a test iOS app that acts as
a peripheral in the way the example project expects it. You can clone the test
app from [here](https://github.com/Wolox/WLXBluetoothDeviceMockPeripheral).

## Installation

**WLXBluetoothDevice** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "WLXBluetoothDevice"

Once the pod is installed you can add the following header to your prefix file:

```objc
#import <WLXBluetoothDevice/WLXBluetoothDevice.h>
```

## Documentation

You can check the library's [wiki](https://github.com/Wolox/WLXBluetoothDevice/wiki)
for documentation and examples of how to use different APIs. If there is
something missing in the wiki you can [![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/Wolox/WLXBluetoothDevice?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge).


## About ##

This project is maintained by [Guido Marucci Blas](https://github.com/guidomb) and it was written by [Wolox](http://www.wolox.com.ar).

![Wolox](https://raw.githubusercontent.com/Wolox/press-kit/master/logos/logo_banner.png)

## License

**WLXBluetoothDevice** is available under the MIT [license](https://raw.githubusercontent.com/Wolox/WLXBluetoothDevice/master/LICENSE).

    Copyright (c) 2014 Guido Marucci Blas <guidomb@wolox.com.ar>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
