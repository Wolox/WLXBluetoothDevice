//
//  WLXDictionaryOfArrays.m
//  Pods
//
//  Created by Guido Marucci Blas on 10/22/14.
//
//

#import "WLXDictionaryOfArrays.h"

#import "WLXBluetoothDeviceHelpers.h"

@interface WLXDictionaryOfArrays ()

@property (nonatomic) NSMutableDictionary * dictionary;

@end

@implementation WLXDictionaryOfArrays

@dynamic count;
@dynamic allKeys;

- (instancetype)init {
    self = [super init];
    if (self) {
        _dictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSArray *)allKeys {
    return self.dictionary.allKeys;
}

- (NSUInteger)count {
    NSUInteger count = 0;
    for (NSArray * array in [self.dictionary allValues]) {
        count += [array count];
    }
    return count;
}

- (void)setObject:(id)object forKey:(id<NSCopying>)key {
    WLXAssertNotNil(key);
    WLXAssertNotNil(object);
    NSMutableArray * array = self.dictionary[key];
    if (array == nil) {
        array = self.dictionary[key] = [[NSMutableArray alloc] init];
    }
    [array addObject:object];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key {
    [self setObject:obj forKey:key];
}

- (NSMutableArray *)objectsForKey:(id)key {
    NSMutableArray * array = self.dictionary[key];
    if (array == nil) {
        array = self.dictionary[key] = [[NSMutableArray alloc] init];
    }
    return array;
}

- (id)objectForKeyedSubscript:(id)key {
    return [self objectsForKey:key];
}


@end
