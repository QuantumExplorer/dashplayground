//
//  Branch+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Branch+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Branch (CoreDataProperties)

+ (NSFetchRequest<Branch *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *amiId;
@property (nullable, nonatomic, copy) NSString *lastCommitSha;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *masternodes;
@property (nullable, nonatomic, retain) Repository *repository;
@property (nullable, nonatomic, retain) NSSet<Masternode *> *sentinels;

@end

@interface Branch (CoreDataGeneratedAccessors)

- (void)addMasternodesObject:(Masternode *)value;
- (void)removeMasternodesObject:(Masternode *)value;
- (void)addMasternodes:(NSSet<Masternode *> *)values;
- (void)removeMasternodes:(NSSet<Masternode *> *)values;

- (void)addSentinelsObject:(Masternode *)value;
- (void)removeSentinelsObject:(Masternode *)value;
- (void)addSentinels:(NSSet<Masternode *> *)values;
- (void)removeSentinels:(NSSet<Masternode *> *)values;

@end

NS_ASSUME_NONNULL_END
