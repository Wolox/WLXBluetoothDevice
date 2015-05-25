#!/bin/bash
xcodebuild -scheme WLXBluetoothDeviceReactiveExtensions -project WLXBluetoothDevice.xcodeproj -sdk iphonesimulator test | xcpretty -c
