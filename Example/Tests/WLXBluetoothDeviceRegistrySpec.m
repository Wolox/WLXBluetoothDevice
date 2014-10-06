//
//  WLXBluetoothDeviceRegistrySpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/5/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXBluetoothDeviceRegistry.h>
#import <WLXBluetoothDevice/WLXBluetoothDeviceNotifications.h>
#import <WLXBluetoothDevice/WLXFakeDateProvider.h>

SpecBegin(WLXBluetoothDeviceRegistry)

    __block id<WLXBluetoothDeviceRepository> mockRepository;
    __block NSNotificationCenter * notificationCenter;
    __block CBCentralManager * mockCentralManager;
    __block WLXBluetoothDeviceRegistry * registry;
    __block CBPeripheral * mockPeripheral;
    __block NSDate * mockDate;

    beforeEach(^{
        mockPeripheral = mock([CBPeripheral class]);
        mockRepository = mockProtocol(@protocol(WLXBluetoothDeviceRepository));
        notificationCenter = [NSNotificationCenter defaultCenter];
        mockCentralManager = mock([CBCentralManager class]);
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"es_AR"]];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
        mockDate = [formatter dateFromString:@"2012-03-01 22:00:00 GMT-03:00"];
        id<WLXDateProvider> dateProvider = [[WLXFakeDateProvider alloc] initWithDate:mockDate];
        [WLXBluetoothDeviceConnectionRecord setDateProvider:dateProvider];
        registry = [[WLXBluetoothDeviceRegistry alloc] initWithRepository:mockRepository
                                                       notificationCenter:notificationCenter
                                                           centralManager:mockCentralManager];
        
        NSUUID * UUID = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
        [MKTGiven([mockPeripheral name]) willReturn:@"Mock Peripheral"];
        [MKTGiven([mockPeripheral identifier]) willReturn:UUID];
        
        [MKTGiven([NSDate date]) willReturn:mockDate];
        
        [MKTGiven([mockCentralManager retrievePeripheralsWithIdentifiers:@[UUID]]) willReturn:@[mockPeripheral]];
        
        id record = [WLXBluetoothDeviceConnectionRecord recordWithPeripheral:mockPeripheral];
        [MKTGiven([mockRepository fetchLastConnectionRecord]) willReturn:record];
    });

    afterEach(^{
        mockCentralManager = nil;
        mockDate = nil;
        mockPeripheral = nil;
        mockRepository = nil;
        notificationCenter = nil;
        registry = nil;
    });

    describe(@"#enabled", ^{
    
        context(@"when the registry is enabled", ^{
        
            beforeEach(^{
                registry.enabled = YES;
            });
            
            context(@"when a new connection is established", ^{
            
                beforeEach(^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished
                                                      object:nil
                                                    userInfo:userInfo];
                });
               
                it(@"saves the connected peripheral into the repository", ^{
                    MKTArgumentCaptor * connectionRecordCaptor = [[MKTArgumentCaptor alloc] init];
                    [MKTVerify(mockRepository) saveConnectionRecord:connectionRecordCaptor.capture];
                    WLXBluetoothDeviceConnectionRecord * connectionRecord = connectionRecordCaptor.value;
                    expect(connectionRecord.name).to.equal(mockPeripheral.name);
                    expect(connectionRecord.UUID).to.equal(mockPeripheral.identifier.UUIDString);
                    expect(connectionRecord.connectionDate).to.equal(mockDate);
                });
                
            });
            
        });
        
        context(@"when the registry is disabled", ^{
           
            context(@"when a new connection is established", ^{

                beforeEach(^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished
                                                      object:nil
                                                    userInfo:userInfo];
                });
            
                it(@"does not save the connected peripheral into the repository", ^{
                    [MKTVerifyCount(mockRepository, never()) saveConnectionRecord:anything()];
                });
            
            });
        });
        
    });

    describe(@"#lastConnectionRecord", ^{
        
        context(@"when the registry is enabled", ^{
        
            beforeEach(^{
                registry.enabled = YES;
            });
            
            context(@"when a new connection is established", ^{
            
                beforeEach(^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished
                                                      object:nil
                                                    userInfo:userInfo];
                });
                
                it(@"returns the last connection record", ^{
                    WLXBluetoothDeviceConnectionRecord * connectionRecord = registry.lastConnectionRecord;
                    expect(connectionRecord.name).to.equal(mockPeripheral.name);
                    expect(connectionRecord.UUID).to.equal(mockPeripheral.identifier.UUIDString);
                    expect(connectionRecord.connectionDate).to.equal(mockDate);
                });
                
            });
            
        });
        
        context(@"when the registry is disabled", ^{
            
            context(@"when a new connection is established", ^{
                
                beforeEach(^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished
                                                      object:nil
                                                    userInfo:userInfo];
                });
                
                it(@"returns the previous connection record", ^{
                    expect(registry.lastConnectionRecord).to.beNil;
                });
                
            });
            
        });
        
    });

    describe(@"#lastConnectionRecord", ^{
    
        context(@"when the registry is enabled", ^{
        
            beforeEach(^{
                registry.enabled = YES;
            });
        
            context(@"when a new connection is established", ^{
            
                beforeEach(^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished
                                                      object:nil
                                                    userInfo:userInfo];
                });
            
                it(@"returns the last connected peripheral", ^{
                    expect(registry.lastConnectedPeripheral).to.equal(mockPeripheral);
                });
            
            });
        
        });
    
        context(@"when the registry is disabled", ^{
        
            context(@"when a new connection is established", ^{
            
                beforeEach(^{
                    NSDictionary * userInfo = @{ WLXBluetoothDevicePeripheral : mockPeripheral };
                    [notificationCenter postNotificationName:WLXBluetoothDeviceConnectionEstablished
                                                      object:nil
                                                    userInfo:userInfo];
                });
            
                it(@"returns the previuos connected peripheral", ^{
                    expect(registry.lastConnectedPeripheral).to.beNil;
                });
            
            });
        
        });
    
    });



SpecEnd