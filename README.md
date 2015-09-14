# WLXBluetoothDevice


[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/Wolox/WLXBluetoothDevice?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![CI Status](https://travis-ci.org/Wolox/WLXBluetoothDevice.svg?branch=master)](https://travis-ci.org/Wolox/WLXBluetoothDevice)
[![Coverage Status](https://coveralls.io/repos/Wolox/WLXBluetoothDevice/badge.png?branch=master)](https://coveralls.io/r/Wolox/WLXBluetoothDevice?branch=master)
[![Release](https://img.shields.io/github/release/Wolox/WLXBluetoothDevice.svg)](https://github.com/Wolox/WLXBluetoothDevice/releases)
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

## Usage

~~To run the example project, clone the repo, and run `pod install` from the Example directory first.
To actually use the example app you need a Bluetooth peripheral that exposes certain
characteristics in a certain way. That is why we made a test iOS app that acts as
a peripheral in the way the example project expects it. You can clone the test
app from [here](https://github.com/Wolox/WLXBluetoothDeviceMockPeripheral).~~

**NOTE**: The example project is currently broken because it uses CocoaPods to install `WLXBluetoothDevice`. The actual code probably works. This will be fixed in future versions. Check issue [#35](https://github.com/Wolox/WLXBluetoothDevice/issues/35).

### Reactive extensions

If you like [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) there is a separate target that adds support for a `RACSignal` based API. All you have to do is add the `WLXBluetoothDeviceReactiveExtensions.framework` to your project.

## Installation

### [Carthage]

[Carthage]: https://github.com/Carthage/Carthage

Add the following to your Cartfile:

```
github "Wolox/WLXBluetoothDevice" ~> 0.2.0
```

Then run `carthage update`.

Follow the current instructions in [Carthage's README][carthage-installation]
for up to date installation instructions.

[carthage-installation]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application

You'll also need to add the following frameworks to your Xcode project:
  * `Box.framework`
  * `CocoaLumberjack.framework`
  * `ReactiveCocoa.framework`
  * `Result.framework`

[Box]: https://github.com/robrix/box
[Result]: https://github.com/antitypical/Result
[ReactiveCocoa]: https://github.com/ReactiveCocoa/ReactiveCocoa
[CocoaLumberjack]: https://github.com/CocoaLumberjack/CocoaLumberjack

### CocoaPods

Installing through CocoaPods is not supported yet. After migrating to Carthage the podspec was broken and CocoaPods support wasn't a priority. Also this projects depends on ReactiveCocoa and there is not official support of ReactiveCocoa in CocoaPods. We still to decide if this is going to be a problem so until the ReactiveCocoa podspec is updated to support `v3.0.0` we will not try to support CocoaPods again.

This issue is being tracked in [#40](https://github.com/Wolox/WLXBluetoothDevice/issues/40). Pull requests are welcomed!!!

## Documentation

You can check the library's [wiki](https://github.com/Wolox/WLXBluetoothDevice/wiki)
for documentation and examples of how to use different APIs. If there is
something missing in the wiki you can [![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/Wolox/WLXBluetoothDevice?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge).

## Development

To start developing you just need to run the following commands:

```
git clone git@github.com:Wolox/WLXBluetoothDevice.git
cd WLXBluetoothDevice
script/bootstrap
open WLXBluetoothDevice.xcodeproj
```

### Scripts

Inside the `script` folder there are several scripts to facilitate the development process. For up to date documentation of this scripts check [this](http://github.com/guidomb/ios-scripts) repository. The most relevant scripts are:

  * `script/bootstrap`: Bootstraps the project for the first time.
  * `script/test`: Runs the project's tests
  * `script/update`: Updates the project's dependencies.

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
