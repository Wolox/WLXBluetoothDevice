//
//  WLXBluetoothDeviceDiscovererSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 9/29/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXBluetoothDeviceDiscoverer.h>

SpecBegin(WLXBluetoothDeviceDiscoverer)

    __block CBCentralManager * centralManager;
    __block WLXBluetoothDeviceDiscoverer * discoverer;
    __block NSNotificationCenter * notificationCenter;
    __block id<WLXDeviceDiscovererDelegate> discovererDelegate;

    beforeEach(^{
        centralManager = mock([CBCentralManager class]);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        notificationCenter = [NSNotificationCenter defaultCenter];
        discoverer = [[WLXBluetoothDeviceDiscoverer alloc] initWithCentralManager:centralManager
                                                               notificationCenter:notificationCenter
                                                                            queue:queue];
        discovererDelegate = mockProtocol(@protocol(WLXDeviceDiscovererDelegate));
        discoverer.delegate = discovererDelegate;
        [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOn object:nil userInfo:nil];
    });

    afterEach(^{
        notificationCenter = nil;
        centralManager = nil;
        discoverer = nil;
        discovererDelegate = nil;
    });

    describe(@"#discoverDevicesNamed:withServices:andTimeout", ^{
        
        afterEach(^{
            [discoverer stopDiscoveringDevices];
        });
        
        context(@"when nil is passed as device name", ^{
            it(@"allows any device to be discovered", ^{
                expect([discoverer discoverDevicesNamed:nil withServices:nil andTimeout:10]).to.beTruthy;
                [MKTVerify(centralManager) scanForPeripheralsWithServices:nil options:discoverer.scanOptions];
            });
        });
            
        context(@"when an device name pattern is given", ^{
            it(@"allows devices matching the given name to be discovered", ^{
                expect([discoverer discoverDevicesNamed:@"Device Name" withServices:nil andTimeout:10]).to.beTruthy;
                [MKTVerify(centralManager) scanForPeripheralsWithServices:nil options:discoverer.scanOptions];
            });
        });
        
        context(@"when nil services UUID is given", ^{
            it(@"allows any device to be discovered", ^{
                expect([discoverer discoverDevicesNamed:nil withServices:nil andTimeout:10]).to.beTruthy;
                [MKTVerify(centralManager) scanForPeripheralsWithServices:nil options:discoverer.scanOptions];
            });
        });
            
        context(@"when an array of services UUIDs is given", ^{
            it(@"only discovers devices that expose at least one of the services", ^{
                NSArray * services = @[
                    [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00067"],
                    [CBUUID UUIDWithString:@"68753A44-4D6F-1226-9C60-0050E4C00063"]
                ];
                expect([discoverer discoverDevicesNamed:nil withServices:services andTimeout:10]).to.beTruthy;
                [MKTVerify(centralManager) scanForPeripheralsWithServices:services options:discoverer.scanOptions];
            });
        });
        
        
        context(@"when 0 is given as timeout", ^{
            
            it(@"raises an exception", ^{
                expect(^{ [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:0]; }).to.raise(@"InvalidTimeoutException");
            });
        });
            
        context(@"when a positive number is given as timeout", ^{
            it(@"stops discovering devices after timeout expired", ^{
                [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:500];
                expect(discoverer.discovering).after(0.6).to.beFalsy;
            });
        });
        
        context(@"when bluetooth is off", ^{
            
            beforeEach(^{
                [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOff object:nil userInfo:nil];
            });
            
            it(@"does not start the discovery process", ^{
                expect([discoverer discoverDevicesNamed:nil withServices:nil andTimeout:10]).to.beFalsy;
            });
            
        });
        
        it(@"changes the discovering status", ^{
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:2000];
            expect(discoverer.discovering).to.beTruthy;
        });
        
        it(@"notifies that the discovery process has started", ^{
            expect(^{
                [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:1000];
            }).to.notify(WLXBluetoothDeviceStartDiscovering);
        });
        
        it(@"invokes the deviceDiscoverer:startDiscoveringDevicesWithTimeout: delegate's method", ^{
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:1000];
            [MKTVerify(discovererDelegate) deviceDiscoverer:discoverer startDiscoveringDevicesWithTimeout:1000];
        });
        
    });

    describe(@"#stopDiscoveringDevices", ^{
    
        beforeEach(^{
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:5000];
        });
        
        it(@"stops scanning devices", ^{
            [discoverer stopDiscoveringDevices];
            [MKTVerify(centralManager) stopScan];
        });
        
        it(@"changes the discovering status", ^{
            [discoverer stopDiscoveringDevices];
            expect(discoverer.discovering).to.beFalsy;
        });
        
        context(@"when the discovery process has already been stopped", ^{
            
            beforeEach(^{
                [discoverer stopDiscoveringDevices];
            });
            
            it(@"does not ask the central to stop scanning", ^{
                [discoverer stopDiscoveringDevices];
                [MKTVerifyCount(centralManager, times(1)) stopScan];
            });
        });
        
        it(@"notifies that the discovery process has been stopped", ^{
            expect(^{
                [discoverer stopDiscoveringDevices]; nil;
            }).to.notify(WLXBluetoothDeviceStoptDiscovering);
        });
        
        it(@"invokes the deviceDiscovererStopDiscoveringDevices: delegate's method", ^{
            [discoverer stopDiscoveringDevices];
            [MKTVerify(discovererDelegate) deviceDiscovererStopDiscoveringDevices:discoverer];
        });
        
    });

    context(@"when the connection is lost while discovering", ^{
        
        beforeEach(^{
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:30000];
        });
        
        it(@"stops the discovery process", ^{
            expect(discoverer.discovering).to.beTruthy;
            [notificationCenter postNotificationName:WLXBluetoothDeviceBluetoothIsOff object:nil userInfo:nil];
            expect(discoverer.discovering).to.beFalsy;
        });
        
        afterEach(^{
            [discoverer stopDiscoveringDevices];
        });
        
    });


    describe(@"#addDiscoveredDevice:", ^{
        
        __block WLXDeviceDiscoveryData * data;
        
        afterEach(^{
            [discoverer stopDiscoveringDevices];
            data = nil;
        });
        
        context(@"when no device name has been provided", ^{
            
            beforeEach(^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Device Name"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
                [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:5000];
            });
            
            it(@"accepts any device", ^{
                expect([discoverer addDiscoveredDevice:data]).to.beTruthy;
            });
            
        });
        
        context(@"when an exact names has been provided", ^{
            
            beforeEach(^{
                [discoverer discoverDevicesNamed:@"Device Name" withServices:nil andTimeout:5000];
            });
            
            it(@"accepts only devices with the specified name", ^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Device Name"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
                expect([discoverer addDiscoveredDevice:data]).to.beTruthy;
            });
            
            it(@"rejects devices with other name", ^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Foo Name"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
                expect([discoverer addDiscoveredDevice:data]).to.beFalsy;
            });
            
        });
        
        context(@"when a regular expression has been provided as name", ^{
            
            beforeEach(^{
                [discoverer discoverDevicesNamed:@"Test device (\\d+)" withServices:nil andTimeout:5000];
            });
            
            it(@"accepts only devices with a name that matches the specified regexp", ^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Test Device 10"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
                expect([discoverer addDiscoveredDevice:data]).to.beTruthy;
            });
            
            it(@"rejects devices with a name that does not match the specified regexp", ^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Foo Name"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
                expect([discoverer addDiscoveredDevice:data]).to.beFalsy;
            });
            
        });
        
        context(@"when the discoverer is not discovering", ^{
            
            beforeEach(^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Device Name"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
            });
            
            it(@"rejects the device", ^{
                expect([discoverer addDiscoveredDevice:data]).to.beFalsy;
            });
            
        });
        
        context(@"when the device has already been discovered", ^{
            
            beforeEach(^{
                CBPeripheral * peripheral = mock([CBPeripheral class]);
                NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
                [MKTGiven([peripheral name]) willReturn:@"Device Name"];
                [MKTGiven([peripheral identifier]) willReturn: UUID];
                data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
                [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:5000];
                [discoverer addDiscoveredDevice:data];
            });
            
            it(@"rejects the device", ^{
                expect([discoverer addDiscoveredDevice:data]).to.beFalsy;
            });
            
        });
        
        it(@"stores the discovered device", ^{
            CBPeripheral * peripheral = mock([CBPeripheral class]);
            NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
            [MKTGiven([peripheral name]) willReturn:@"Device Name"];
            [MKTGiven([peripheral identifier]) willReturn: UUID];
            data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:5000];
            [discoverer addDiscoveredDevice:data];
            expect(discoverer.discoveredDevices).to.equal(@[data]);
        });
        
        it(@"notifies that a device has been discovered", ^{
            CBPeripheral * peripheral = mock([CBPeripheral class]);
            NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
            [MKTGiven([peripheral name]) willReturn:@"Device Name"];
            [MKTGiven([peripheral identifier]) willReturn: UUID];
            data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:5000];
            NSNotification * notification = [NSNotification notificationWithName:WLXBluetoothDeviceDeviceDiscovered
                                                                          object:discoverer
                                                                        userInfo:@{WLXBluetoothDeviceDiscoveryData: data}];
            
            expect(^{
                [discoverer addDiscoveredDevice:data];
            }).to.notify(notification);
        });
        
        it(@"invokes the deviceDiscoverer:discoveredDevice: delegate's method", ^{
            CBPeripheral * peripheral = mock([CBPeripheral class]);
            NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00069"];
            [MKTGiven([peripheral name]) willReturn:@"Device Name"];
            [MKTGiven([peripheral identifier]) willReturn: UUID];
            data = [[WLXDeviceDiscoveryData alloc] initWithPeripheral:peripheral advertisementData:@{} RSSI:@(10)];
            [discoverer discoverDevicesNamed:nil withServices:nil andTimeout:5000];
            [discoverer addDiscoveredDevice:data];
            [MKTVerify(discovererDelegate) deviceDiscoverer:discoverer discoveredDevice:data];
        });
        
    });

SpecEnd