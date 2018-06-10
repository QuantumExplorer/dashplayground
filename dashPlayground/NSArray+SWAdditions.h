//
//  NSArray+Additions.h
//  DASH Playground
//
//  Created by Samuel Westrich on 3/7/16.
//  Copyright (c) 2017 Samuel Westrich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSArray (SWAdditions)

+(NSArray*)sharedInstance;

- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key;

- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key objectPath:(NSString*)object;

- (NSMutableDictionary *)mutableDictionaryReferencedByKeyPath:(NSString*)key objectPathMakeMutable:(NSString*)objectPath;

- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key objectPaths:(NSArray*)objectPaths;

- (NSDictionary *)mutableDictionaryReferencedByKeyPath:(NSString*)key;

- (NSArray *)arrayReferencedByKeyPath:(NSString*)key;

- (BOOL)isSortedOnKeyPath:(NSString*)key;

- (NSArray *)arrayOfArraysReferencedByKeyPaths:(NSArray*)keyPaths requiredKeyPaths:(NSArray*)requiredKeyPaths;

- (NSArray *)arrayOfDictionariesReferencedByKeyPaths:(NSArray*)keyPaths forceString:(BOOL)forceString;

- (NSArray *)arrayByCrushingSubArrays;

- (NSArray *)arrayByCrushingSubSets;

- (NSMutableArray *)mutableArrayReferencedByKeyPath:(NSString*)key;

- (NSDictionary *)dictionaryOfArraysReferencedByKeyPath:(NSString*)key;

- (NSDictionary *)mutableDictionaryOfArraysReferencedByKeyPath:(NSString*)key;

- (NSArray *)arrayByRemovingObjectsFromArray:(NSArray*)arrayOfElementsToRemove;

- (NSInteger)indexForInsertionOfObject:(id)object keyPathAndOrderOfKeyPathArrays:(NSArray*)keyPathAndOrderOfKeyPathArrays;

- (NSString *)stringByJoiningOnProperty:(NSString *)property separator:(NSString *)separator;

- (NSString *)stringByJoiningOnObject:(NSString *)objectString subProperty:(NSString*)subProperty separator:(NSString *)separator;

@end
