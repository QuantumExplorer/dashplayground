//
//  DPDataStore.m
//  Dash Playground
//
//  Created by Sam Westrich on 1/7/16.
//  Copyright © 2016 Sam Westrich. All rights reserved.
//

#import "DPDataStore.h"
#import "AppDelegate.h"
#import "NSArray+SWAdditions.h"
#import "NSData+Security.h"
#import "Repository+CoreDataClass.h"
#import "Branch+CoreDataClass.h"
#import "Masternode+CoreDataClass.h"

@implementation DPDataStore


#pragma mark - Repositories

-(NSArray*)allRepositories {
    return [self allRepositoriesInContext:self.mainContext];
}
-(NSArray*)allRepositoriesInContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Repository"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    
    NSArray *repositories = [self executeFetchRequest:fetchRequest inContext:context error:&error];
    if (!repositories) {
        return @[];
    } else  {
        return repositories;
    }
}

-(void)deleteRepository:(Repository*)repository {
    
    [self.mainContext deleteObject:repository];
    [self saveMainContext];
}

-(void)deleteBranch:(Branch*)branch {
    [self.mainContext deleteObject:branch];
    [self saveMainContext];
}

-(Branch*)branchNamed:(NSString*)branchName inRepository:(Repository*)repository {
    if (!repository) {
        return nil;
    }
    else  {
        NSSet * set = [repository.branches filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@",branchName]];
        if (!set || ![set count]) {
            return [self createBranch:branchName onRepository:repository saveContext:TRUE];
        } else {
             return [set anyObject];
        }
    }
}

-(Repository*)repositoryNamed:(NSString*)name forOwner:(NSString*)owner inProject:(DPRepositoryProject)project onRepositoryURLPath:(NSString*)repositoryURLPath {
    return [self repositoryNamed:name forOwner:owner inProject:project onRepositoryURLPath:repositoryURLPath inContext:self.mainContext saveContext:NO];
}

-(Repository*)repositoryNamed:(NSString*)name forOwner:(NSString*)owner inProject:(DPRepositoryProject)project onRepositoryURLPath:(NSString*)repositoryURLPath inContext:(NSManagedObjectContext*)context saveContext:(BOOL)saveContext {
    if (project == DPRepositoryProject_All) return nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Repository"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setReturnsObjectsAsFaults:FALSE];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"project == %@ && url == %@",@(project),repositoryURLPath]];
    
    NSError *error = nil;
    
    NSArray *repositories = [self executeFetchRequest:fetchRequest inContext:context error:&error];
    if ([repositories count]) {
        return [repositories firstObject];
    } else {
        return [self createRepositoryNamed:name withOwner:owner inProject:project onRepositoryURLPath:repositoryURLPath inContext:context saveContext:saveContext];
    }
}

-(Repository*)createRepositoryNamed:(NSString*)name withOwner:(NSString*)owner inProject:(DPRepositoryProject)project onRepositoryURLPath:(NSString*)repositoryURLPath inContext:(NSManagedObjectContext*)context saveContext:(BOOL)saveContext {
    Repository *repository = (Repository*)[self createInsertedNewObjectForEntityNamed:@"Repository" inContext:context];
    repository.url = repositoryURLPath;
    repository.project = project;
    repository.name = name;
    repository.owner = owner;
    if (saveContext)
        [self saveContext:context];
    return repository;
}

-(Branch*)createBranch:(NSString*)branchName onRepository:(Repository*)repository saveContext:(BOOL)saveContext {
    Branch *branch = (Branch*)[self createInsertedNewObjectForEntityNamed:@"Branch" inContext:repository.managedObjectContext];
    branch.name = branchName;
    branch.repository = repository;
    if (saveContext)
        [self saveContext:repository.managedObjectContext];
    return branch;
}

#pragma mark - Message

-(void)createMessageToMasternode:(NSManagedObject*)masternode dataType:(int)dataType atLine:(int)line {
    [self createMessageToMasternode:masternode dataType:dataType atLine:line inContext:self.mainContext saveContext:FALSE];
}

-(NSManagedObject*)createMessageToMasternode:(NSManagedObject*)masternode dataType:(int)dataType atLine:(int)line
                                 inContext:(NSManagedObjectContext*)context saveContext:(BOOL)saveContext {
    NSManagedObject *messageObject = (NSManagedObject*)[self createInsertedNewObjectForEntityNamed:@"Message" inContext:context];
    [messageObject setValue:@(dataType) forKey:@"type"];
    [messageObject setValue:@(line) forKey:@"atLine"];
//    [messageObject setValue:message forKey:@"message"];
//    [messageObject setValue:masternode forKey:@"masternode"];
    if (saveContext) {
        [self saveContext:context];
    }
    return messageObject;
}

-(NSArray*)getMessageObjectsFromMasternode:(NSManagedObject *)masternode {
    return [self getLogMessageFromMasternode:masternode inContext:self.mainContext];
}

-(NSArray*)getLogMessageFromMasternode:(NSManagedObject *)masternode inContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message"
                                              inManagedObjectContext:context];
//    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"masternode == %@",masternode]];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    
    NSArray *messageObject = [self executeFetchRequest:fetchRequest inContext:context error:&error];
    if ([messageObject count] == 0) {
        return nil;
    } else  {
        return messageObject;
    }
    
}

#pragma mark - Masternodes

-(NSArray*)allMasternodes {
    return [self allMasternodesInContext:self.mainContext];
}
-(NSArray*)allMasternodesInContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Masternode"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    
    NSArray *masternodes = [self executeFetchRequest:fetchRequest inContext:context error:&error];
    if (!masternodes) {
        return @[];
    } else  {
        return masternodes;
    }
}

-(NSArray*)allMasternodesWithPredicate:(NSPredicate*)predicate {
    return [self allMasternodesWithPredicate:predicate inContext:self.mainContext];
}

-(NSArray*)allMasternodesWithPredicate:(NSPredicate*)predicate inContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Masternode"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    
    NSArray *masternodes = [self executeFetchRequest:fetchRequest inContext:context error:&error];
    if (!masternodes) {
        return @[];
    } else  {
        return masternodes;
    }
}


- (NSManagedObject*)addMasternode:(NSDictionary*)values saveContext:(BOOL)saveContext {
#if LOG_RVC_CALLS
    NSLog(@"-(NSManagedObject*)addMasternode:(NSDictionary*)values");
#endif
    [self verifyMainThread];
    NSManagedObject *masternode = (NSManagedObject*)[self createInsertedNewObjectForEntityNamed:@"Masternode"];
    [masternode setValuesForKeysWithDictionary:values];
    if (saveContext)
        [self saveContext];
    return masternode;
}

-(void)updateMasternode:(NSString*)masternodeId withState:(InstanceState)state {
    [self updateMasternode:masternodeId withState:state inContext:self.mainContext];
}

-(NSManagedObject*)updateMasternode:(NSString*)masternodeId withState:(InstanceState)state inContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Masternode"
                                              inManagedObjectContext:context];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"instanceId == %@",masternodeId]];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    
    NSArray *masternodes = [self executeFetchRequest:fetchRequest inContext:context error:&error];
    if (!masternodes) {
        return nil;
    } else  {
        [[masternodes objectAtIndex:0] setValue:@(state) forKey:@"instanceState"];
        [self saveContext:context];
        return [masternodes objectAtIndex:0];
    }
    
}


#pragma mark - General

#define LOG_LEVEL 1
#define LOG_BACKGROUND_CALLS 0


#if LOG_BACKGROUND_CALLS
static NSTimeInterval totalTime = 0.0f;
__strong static NSMutableDictionary * mDict = nil;
#endif

-(NSArray *)executeFetchRequest:(NSFetchRequest*)request inContext:(NSManagedObjectContext*)context error:(__autoreleasing NSError**)error {
    if ([NSThread isMainThread]) {
        //LGLog(@"executing fetch request on main thread");
#if LOG_BACKGROUND_CALLS
        NSDate * date = [NSDate date];
#endif
        id returnData = [context executeFetchRequest:request error:error];
#if LOG_BACKGROUND_CALLS
        NSTimeInterval thisInterval = [[NSDate date] timeIntervalSinceDate:date];
        totalTime += thisInterval;
#endif
        //LGLog(@"took %.5f (%.5f)",thisInterval,totalTime);
        return returnData;
        
    } else {
#if LOG_BACKGROUND_CALLS
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            mDict = [NSMutableDictionary dictionary];
        });
        NSArray * callStackSymbols = [NSThread callStackSymbols];
        NSString * level = [callStackSymbols objectAtIndex:LOG_LEVEL];
        NSError *error = NULL;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\].]*\\]" options:NSRegularExpressionCaseInsensitive error:&error];
        
        
        [regex enumerateMatchesInString:level options:0 range:NSMakeRange(0, [level length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            
            // detect
            NSString *insideString = [level substringWithRange:[match range]];
            if ([mDict objectForKey:insideString]) {
                [mDict setObject:@([[mDict objectForKey:insideString] integerValue] + 1) forKey:insideString];
            } else {
                [mDict setObject:@(1) forKey:insideString];
            }
            //print
            NSLog(@"%@",mDict);
            
        }];
#endif
        __block NSError *theError = nil;
        __block NSArray *rArray;
        //NSThread * thread = [NSThread currentThread];
        [context performBlockAndWait:^{
            //NSThread * blockThread = [NSThread currentThread];
            //NSAssert(blockThread == thread, @"should be same threads");
            rArray = [context executeFetchRequest:request error:&theError];
        }];
        return rArray;
    }
}

-(void)executeFetchRequestAsynchronously:(NSFetchRequest*)request inContext:(NSManagedObjectContext*)context completion:(FetchRequestCompletion)completion {
    
    [context performBlock:^{
        NSError *rError = nil;
        NSArray * requestArray = [context executeFetchRequest:request error:&rError];
        completion(requestArray,&rError);
    }];
}

-(NSInteger)executeCountRequest:(NSFetchRequest*)request inContext:(NSManagedObjectContext*)context error:(__autoreleasing NSError**)error {
    if ([NSThread isMainThread]) {
        return [context countForFetchRequest:request error:error];
    } else {
        __block NSError *theError = nil;
        __block NSInteger rArray;
        [context performBlockAndWait:^{
            rArray = [context countForFetchRequest:request error:&theError];
        }];
        return rArray;
    }
}

-(NSManagedObjectContext*)mainContext {
    return [((AppDelegate*)[NSApplication sharedApplication].delegate) managedObjectContext];
}

-(dispatch_queue_t)queryCacheDispatchQueue {
    static dispatch_queue_t queryCacheDispatchQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queryCacheDispatchQueue = dispatch_queue_create("com.langical.langical.queryCacheQueue", DISPATCH_QUEUE_SERIAL);
        // Do any other initialisation stuff here
    });
    return queryCacheDispatchQueue;
}

-(NSManagedObjectContext*)createContextOffMainContext {
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setParentContext:[self mainContext]];
    [context setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType]]; //this policy means that local changes are more important (the user is currently modifying an entry, we don't care about the server version in a conflict
    return context;
}

- (void)saveMainContext {
    if ([NSThread isMainThread]) {
        [self saveContext];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveContext];
        });
    }
}



- (void)saveContext {
    [self verifyMainThread];
    NSManagedObjectContext *context = [self mainContext];
    
    [self saveContext: context];
}

- (void)saveContext:(NSManagedObjectContext*)context {
#if LOG_DATASTORE_SAVE_CONTEXT_BACKGROUND_THREAD_STACKTRACE
    if (context.parentContext)
        NSLog(@"saving stack trace  of save Context %@",[NSThread callStackSymbols]);
#endif
#if LOG_DATASTORE_SAVE_CONTEXT_INSERTED_OBJECTS
    NSLog(@"context inserted objects %@",[context insertedObjects]);
#endif
#if LOG_DATASTORE_SAVE_CONTEXT_DELETED_OBJECTS
    NSLog(@"context deleted objects %@",[context deletedObjects]);
#endif
#if LOG_DATASTORE_SAVE_CONTEXT_CHANGED_OBJECTS
    NSLog(@"context updated objects %@",[context updatedObjects]);
#endif
    
#if LOG_DATASTORE_SAVE_CONTEXT_MAIN_THREAD_TIMER
    static NSTimeInterval totalTime = 0.0f;
    clock_t start = clock();
#endif
    //    //trying this out
    //    [context performBlock:^{
    NSError * error = nil;
    if (context != nil) {
        if ([context hasChanges] && ![context save:&error]) {
            // If Cocoa generated the error...
            if ([[error domain] isEqualToString:@"NSCocoaErrorDomain"]) {
                // ...check whether there's an NSDetailedErrors array
                NSDictionary *userInfo = [error userInfo];
                if ([userInfo valueForKey:@"NSDetailedErrors"] != nil) {
                    // ...and loop through the array, if so.
                    NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
                    for (NSError *anError in errors) {
                        
                        NSDictionary *subUserInfo = [anError userInfo];
                        // Granted, this indents the NSValidation keys rather a lot
                        // ...but it's a small loss to keep the code more readable.
                        NSLog(@"error info %@", userInfo);
                        NSLog(@"Core Data Save Error\n\n \
                              NSValidationErrorKey\n%@\n\n \
                              NSValidationErrorPredicate\n%@\n\n \
                              NSValidationErrorObject\n%@\n\n \
                              NSLocalizedDescription\n%@",
                              [subUserInfo valueForKey:@"NSValidationErrorKey"],
                              [subUserInfo valueForKey:@"NSValidationErrorPredicate"],
                              [subUserInfo valueForKey:@"NSValidationErrorObject"],
                              [subUserInfo valueForKey:@"NSLocalizedDescription"]);
                    }
                }
                // If there was no NSDetailedErrors array, print values directly
                // from the top-level userInfo object. (Hint: all of these keys
                // will have null values when you've got multiple errors sitting
                // behind the NSDetailedErrors key.
                else {
                    NSLog(@"error info %@", userInfo);
                    NSLog(@"Core Data Save Error\n\n \
                          NSValidationErrorKey\n%@\n\n \
                          NSValidationErrorPredicate\n%@\n\n \
                          NSValidationErrorObject\n%@\n\n \
                          NSLocalizedDescription\n%@",
                          [userInfo valueForKey:@"NSValidationErrorKey"],
                          [userInfo valueForKey:@"NSValidationErrorPredicate"],
                          [userInfo valueForKey:@"NSValidationErrorObject"],
                          [userInfo valueForKey:@"NSLocalizedDescription"]);
                    
                }
            }
            // Handle mine--or 3rd party-generated--errors
            else {
                NSLog(@"Custom Error: %@", [error localizedDescription]);
            }
        }else {
#if LOG_DATASTORE_SAVE_CONTEXT_STACKTRACE
            NSLog(@"Context saved successfully");
            NSLog(@"Toey");
#endif
        }
    }
    
    
    
#if LOG_DATASTORE_SAVE_CONTEXT_MAIN_THREAD_TIMER
    BOOL shouldShowStackTrace = FALSE;
#if LOG_DATASTORE_SAVE_CONTEXT_MAIN_THREAD_STACKTRACE
    shouldShowStackTrace = TRUE;
#endif
    
    if (!context.parentContext) {
        NSTimeInterval time = (float)(clock() - start)/(float)CLOCKS_PER_SEC;
        totalTime += time;
        if (shouldShowStackTrace) {
            NSLog(@"save time %.2f total %.2f stack %@",time,totalTime,[NSThread callStackSymbols]);
        } else {
            NSLog(@"save time %.2f total %.2f",time,totalTime);
        }
    }
#else
#if LOG_DATASTORE_SAVE_CONTEXT_BACKGROUND_THREAD_STACKTRACE
    if (!context.parentContext)
        NSLog(@"saving stack trace  of save Context %@",[NSThread callStackSymbols]);
#endif
#endif
    //    }];
}

-(void)deleteObject:(id)object {
    [((NSManagedObject*)object).managedObjectContext deleteObject:object];
}


-(id)createInsertedNewObjectForEntityNamed:(NSString*)entityName {
    [self verifyMainThread];
    NSManagedObjectContext *context = [self mainContext];
    return [self createInsertedNewObjectForEntityNamed:entityName inContext:context];
}

-(id)createInsertedNewObjectForEntityNamed:(NSString*)entityName inContext:(NSManagedObjectContext*)context {
#if LOG_DATASTORE_INSERT_OBJECT_STACKTRACE
    NSLog(@"saving stack trace of insertion of %@ -> %@",entityName,[NSThread callStackSymbols]);
#endif
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}

-(void)verifyMainThread {
    NSAssert([NSThread isMainThread], @"this needs to be done on the main thread");
}


#pragma mark - Testing Methods

-(void)logDatabase {
    [self verifyMainThread];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    NSManagedObjectContext *context = [self mainContext];
#pragma clang diagnostic pop
    
}


#pragma mark -
#pragma mark Singleton methods

+ (DPDataStore *)sharedInstance
{
    static DPDataStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPDataStore alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _chainNetwork = @"testnet";
    }
    return self;
}

@end

