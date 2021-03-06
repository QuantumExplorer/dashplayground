//
//  Branch+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Branch+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Branch (CoreDataProperties)

+ (NSFetchRequest<Branch *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *amiId;
@property (nullable, nonatomic, copy) NSString *lastCommitHash;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *coreMasternodes;
@property (nullable, nonatomic, retain) Repository *repository;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *sentinelMasternodes;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *driveMasternodes;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *dapiMasternodes;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *insightMasternodes;
@property (nullable, nonatomic, retain) NSSet<Commit *> *commits;

@end

@interface Branch (CoreDataGeneratedAccessors)

- (void)addCoreMasternodesObject:(Masternode *)value;
- (void)removeCoreMasternodesObject:(Masternode *)value;
- (void)addCoreMasternodes:(NSSet<Masternode *> *)values;
- (void)removeCoreMasternodes:(NSSet<Masternode *> *)values;

- (void)addSentinelMasternodesObject:(Masternode *)value;
- (void)removeSentinelMasternodesObject:(Masternode *)value;
- (void)addSentinelMasternodes:(NSSet<Masternode *> *)values;
- (void)removeSentinelMasternodes:(NSSet<Masternode *> *)values;

- (void)addDriveMasternodesObject:(Masternode *)value;
- (void)removeDriveMasternodesObject:(Masternode *)value;
- (void)addDriveMasternodes:(NSSet<Masternode *> *)values;
- (void)removeDriveMasternodes:(NSSet<Masternode *> *)values;

- (void)addDapiMasternodesObject:(Masternode *)value;
- (void)removeDapiMasternodesObject:(Masternode *)value;
- (void)addDapiMasternodes:(NSSet<Masternode *> *)values;
- (void)removeDapiMasternodes:(NSSet<Masternode *> *)values;

- (void)addInsightMasternodesObject:(Masternode *)value;
- (void)removeInsightMasternodesObject:(Masternode *)value;
- (void)addInsightMasternodes:(NSSet<Masternode *> *)values;
- (void)removeInsightMasternodes:(NSSet<Masternode *> *)values;

- (void)addCommitsObject:(Commit *)value;
- (void)removeCommitsObject:(Commit *)value;
- (void)addCommits:(NSSet<Commit *> *)values;
- (void)removeCommits:(NSSet<Commit *> *)values;

@end

NS_ASSUME_NONNULL_END
