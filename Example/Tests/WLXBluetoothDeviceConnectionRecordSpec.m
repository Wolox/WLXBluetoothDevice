//
//  WLXBluetoothDeviceConnectionRecordSpec.m
//  WLXBluetoothDevice
//
//  Created by Guido Marucci Blas on 10/1/14.
//  Copyright (c) 2014 Guido Marucci Blas. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WLXBluetoothDevice/WLXBluetoothDeviceConnectionRecord.h>

SpecBegin(WLXBluetoothDeviceConnectionRecord)

    __block WLXBluetoothDeviceConnectionRecord * connectionRecord;

    beforeEach(^{
        connectionRecord = [[WLXBluetoothDeviceConnectionRecord alloc] initWithUUID:@"FAKEUUID"
                                                                               name:@"Fake name"
                                                                     connectionDate:[NSDate date]];
    });

    afterEach(^{
        connectionRecord = nil;
    });

    describe(@"conforms to NSCoding protocol", ^{
        
        __block WLXBluetoothDeviceConnectionRecord * decodedRecord;
        
        beforeEach(^{
            NSData * data = [NSKeyedArchiver archivedDataWithRootObject:connectionRecord];
            decodedRecord = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        });
        
        afterEach(^{
            decodedRecord = nil;
        });
    
        it(@"encode/decodes the UUID attribute", ^{
            expect(decodedRecord.UUID).to.equal(connectionRecord.UUID);
        });
        
        it(@"encode/decodes the name attribute", ^{
            expect(decodedRecord.name).to.equal(connectionRecord.name);
        });
        
        it(@"encode/decodes the connectionDate attribute", ^{
            expect(decodedRecord.connectionDate).to.equal(connectionRecord.connectionDate);
        });
        
    });

SpecEnd