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
#import "Repository+CoreDataClass.h"

@class Repository,Branch;

typedef void(^FetchRequestCompletion)(NSArray * requestArray, NSError** error);

@interface DPDataStore : NSObject

@property(strong, nonatomic) NSString *chainNetwork;
@property(strong, nonatomic) NSString *githubUsername;
@property(strong, nonatomic) NSString *githubPassword;

+(DPDataStore*)sharedInstance;

#pragma mark - Repositories

-(Branch*)branchNamed:(NSString*)string inProject:(DPRepositoryProject)project onRepositoryURLPath:(NSString*)repositoryURLPath;

#pragma mark - Masternodes

-(NSArray*)allMasternodes;

-(NSArray*)allMasternodesWithPredicate:(NSPredicate*)predicate;

-(NSArray*)allMasternodesWithPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*)context;

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

-(id)createInsertedNewObjectForEntityNamed:(NSString*)entityName;

-(id)createInsertedNewObjectForEntityNamed:(NSString*)entityName inContext:(NSManagedObjectContext*)context;

-(void)logDatabase;

-(dispatch_queue_t)queryCacheDispatchQueue;

-(NSArray*)allRepositories;

-(NSManagedObject*)branchNamed:(NSString*)branchName inRepository:(NSManagedObject*)repository;

-(void)deleteRepository:(NSManagedObject*)object;

-(void)createMessageToMasternode:(NSManagedObject*)masternode dataType:(int)dataType atLine:(int)line;

-(NSArray*)getMessageObjectsFromMasternode:(NSManagedObject *)masternode;

-(NSString*)getGithubAccessToken;

-(void)setGithubAccessToken:(NSString *)githubAccessToken;

-(NSString*)getGithubSSHPath;

-(void)setGithubSSHPath:(NSString *)githubSshPath;

@end
