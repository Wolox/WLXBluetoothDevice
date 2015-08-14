//
//  WLXBluetoothDeviceUserDefaultsRepositorySpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/1/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//
#import "SpecHelper.h"

#import <WLXBluetoothDevice/WLXBluetoothDeviceUserDefaultsRepository.h>

SpecBegin(WLXBluetoothDeviceUserDefaultsRepository)

    __block WLXBluetoothDeviceUserDefaultsRepository * repository;
    __block NSUserDefaults * mockUserDefaults;
    __block WLXBluetoothDeviceConnectionRecord * connectionRecord1;
    __block WLXBluetoothDeviceConnectionRecord * connectionRecord2;
    __block NSData * encodedConnectionRecords;

    beforeEach(^{
        mockUserDefaults = mock([NSUserDefaults class]);
        repository = [[WLXBluetoothDeviceUserDefaultsRepository alloc] initWithUserDefaults:mockUserDefaults];
        connectionRecord1 = [[WLXBluetoothDeviceConnectionRecord alloc] initWithUUID:@"FAKEUUID-001"
                                                                                name:@"Fake name"
                                                                      connectionDate:[NSDate date]];
        connectionRecord2 = [[WLXBluetoothDeviceConnectionRecord alloc] initWithUUID:@"FAKEUUID-002"
                                                                                name:@"Fake name"
                                                                      connectionDate:[NSDate date]];
        encodedConnectionRecords = [NSKeyedArchiver archivedDataWithRootObject:@[connectionRecord2, connectionRecord1]];
        
        [MKTGiven([mockUserDefaults synchronize]) willReturnBool:YES];
    });

    afterEach(^{
        mockUserDefaults = nil;
        repository = nil;
        connectionRecord1 = nil;
        connectionRecord2 = nil;
        encodedConnectionRecords = nil;
    });

    describe(@"#saveConnectionRecord:withBlock:", ^{
        
        context(@"when the record to be saved hasn't been saved before", ^{
            
            __block NSData * archivedObject;
            
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:nil];
                archivedObject = [NSKeyedArchiver archivedDataWithRootObject:@[connectionRecord1]] ;
            });
            
            it(@"stores the record in the user defaults", ^{
                [repository saveConnectionRecord:connectionRecord1 withBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    [MKTVerify(mockUserDefaults) setObject:archivedObject forKey:WLXBluetoothDeviceConnectionRecords];
                }];
            });
            
        });
        
        context(@"when the record to be saved has been saved before", ^{
            
            __block WLXBluetoothDeviceConnectionRecord * newConnectionRecord;
            __block NSData * newEncodedConnectionRecords;
            
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:encodedConnectionRecords];
                newConnectionRecord = [[WLXBluetoothDeviceConnectionRecord alloc] initWithUUID:@"FAKEUUID-001"
                                                                                          name:@"Fake name (new version)"
                                                                                connectionDate:[NSDate date]];
                newEncodedConnectionRecords = [NSKeyedArchiver archivedDataWithRootObject:@[newConnectionRecord, connectionRecord2]];
            });
            
            it(@"stores the newest version record in the user defaults", ^{
                [repository saveConnectionRecord:newConnectionRecord withBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    [MKTVerify(mockUserDefaults) setObject:newEncodedConnectionRecords forKey:WLXBluetoothDeviceConnectionRecords];
                }];
            });
            
        });
        
    });

    describe(@"#fetchLastConnectionRecord:withBlock:", ^{
    
        context(@"when a connection record was saved", ^{
        
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:encodedConnectionRecords];
            });
            
            it(@"returns the latest saved record", ^{
                [repository fetchLastConnectionRecordWithBlock:^(NSError * error, WLXBluetoothDeviceConnectionRecord * record) {
                    expect(record).to.equal(connectionRecord2);
                }];
            });
            
        });
        
        context(@"when a connection record was not saved", ^{
            
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:nil];
            });
            
            it(@"fetches the record from the user defaults", ^{
                [repository fetchLastConnectionRecordWithBlock:^(NSError * error, WLXBluetoothDeviceConnectionRecord * record) {
                    expect(record).to.beNil;
                }];
            });
            
        });
        
    });

    describe(@"#fetchConnectionRecordsWithBlock:", ^{
    
        context(@"when connection records were saved", ^{
        
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:encodedConnectionRecords];
            });
        
            it(@"returns the saved records", ^{
                [repository fetchConnectionRecordsWithBlock:^(NSError * error, NSArray * records) {
                    expect(records).to.equal(@[connectionRecord2, connectionRecord1]);
                }];
            });
        
        });
    
        context(@"when a connection records were not saved", ^{
        
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:nil];
            });
        
            it(@"returns an empty array", ^{
                [repository fetchConnectionRecordsWithBlock:^(NSError * error, NSArray * records) {
                    expect(records).to.equal(@[]);
                }];
            });
        
        });
    
    });


    describe(@"#deleteConnectionRecord:withBlock:", ^{
    
        context(@"when a connection record was saved", ^{
        
            __block NSData * newEncodedConnectionRecords;
            
            beforeEach(^{
                [MKTGiven([mockUserDefaults objectForKey:WLXBluetoothDeviceConnectionRecords]) willReturn:encodedConnectionRecords];
                newEncodedConnectionRecords = [NSKeyedArchiver archivedDataWithRootObject:@[connectionRecord2]];
            });
        
            it(@"deletes the connection record", ^{
                [repository deleteConnectionRecord:connectionRecord1 withBlock:^(NSError * error) {
                    expect(error).to.beNil;
                    [MKTVerify(mockUserDefaults) setObject:newEncodedConnectionRecords forKey:WLXBluetoothDeviceConnectionRecords];
                }];
            });
        
        });
    
});

SpecEnd