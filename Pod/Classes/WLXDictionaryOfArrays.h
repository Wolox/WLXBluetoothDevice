//
//  WLXDictionaryOfArrays.h
//  Pods
//
//  Created by Guido Marucci Blas on 10/22/14.
//
//

#import <Foundation/Foundation.h>

@interface WLXDictionaryOfArrays : NSObject

@property(readonly, copy) NSArray *allKeys;
@property(readonly) NSUInteger count;

- (void)setObject:(id)object forKey:(id<NSCopying>)key;

- (NSMutableArray *)objectsForKey:(id)key;

- (id)objectForKeyedSubscript:(id)key;

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key;

@end
