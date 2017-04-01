//
//  DPDataStore.h
//  Dash Playground
//
//  Created by Sam Westrich on 1/7/16.
//  Copyright © 2016 Sam Westrich. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "InstanceStateTransformer.h"

typedef void(^FetchRequestCompletion)(NSArray * requestArray, NSError** error);

@interface DPDataStore : NSObject

+(DPDataStore*)sharedInstance;

#pragma mark - Masternodes

-(NSArray*)allMasternodes;

-(NSArray*)allMasternodesInContext:(NSManagedObjectContext*)context;

-(void)updateMasternode:(NSString*)masternodeId withState:(InstanceState)state;

- (NSManagedObject*)addMasternode:(NSDictionary*)values saveContext:(BOOL)saveContext;

#pragma mark - Context

-(void)executeFetchRequestAsynchronously:(NSFetchRequest*)request inContext:(NSManagedObjectContext*)context completion:(FetchRequestCompletion)completion;

-(NSArray *)executeFetchRequest:(NSFetchRequest*)request inContext:context error:(NSError**)error;

-(NSManagedObjectContext*)createContextOffMainContext;

-(NSManagedObjectContext*)mainContext;

-(void)saveContext;

-(void)saveContext:(NSManagedObjectContext*)context;

-(void)deleteObject:(id)object;

-(void)deleteObject:(id)object inContext:(NSManagedObjectContext*)context;

-(id)createInsertedNewObjectForEntityNamed:(NSString*)entityName;

-(id)createInsertedNewObjectForEntityNamed:(NSString*)entityName inContext:(NSManagedObjectContext*)context;

-(void)logDatabase;

-(dispatch_queue_t)queryCacheDispatchQueue;



@end
