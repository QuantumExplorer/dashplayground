//
//  Masternode+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Masternode+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Masternode (CoreDataProperties)

+ (NSFetchRequest<Masternode *> *)fetchRequest;

@property (nonatomic) int32_t currentLogLine;
@property (nullable, nonatomic, copy) NSDate *debugLastFetched;
@property (nonatomic) int32_t debugLineCount;
@property (nullable, nonatomic, copy) NSString *debugOutput;
@property (nullable, nonatomic, copy) NSString *coreGitCommitVersion;
@property (nullable, nonatomic, copy) NSString *instanceId;
@property (nonatomic) int16_t instanceState;
@property (nonatomic) int16_t instanceType;
@property (nonatomic) BOOL isSelected;
@property (nullable, nonatomic, copy) NSString *key;

@property (nonatomic) float operationPercentageDone;
@property (nullable, nonatomic, copy) NSString *publicIP;
@property (nullable, nonatomic, copy) NSString *repositoryUrl;
@property (nullable, nonatomic, copy) NSString *rpcPassword;


@property (nullable, nonatomic, copy) NSString *sentinelUrl;
@property (nullable, nonatomic, copy) NSString *sentinelVersion;
@property (nonatomic) int16_t syncStatus;
@property (nullable, nonatomic, copy) NSString *transactionId;
@property (nonatomic) int16_t transactionOutputIndex;
@property (nullable, nonatomic, copy) NSString *coreSemanticVersion;
@property (nonatomic) int64_t lastKnownHeight;
@property (nullable, nonatomic, copy) NSString *chainNetwork;
@property (nullable, nonatomic, copy) NSDate *createdAt;

@property (nonatomic) int16_t nodeVersion;
@property (nonatomic) BOOL installedNVM;
@property (nonatomic) BOOL installedPM2;

@property (nonatomic) int16_t dashcoreState;
@property (nonatomic) int16_t dapiState;
@property (nonatomic) int16_t driveState;
@property (nonatomic) int16_t insightState;
@property (nonatomic) int16_t sentinelState;

@property (nullable, nonatomic, copy) NSString *dapiGitCommitVersion;
@property (nullable, nonatomic, copy) NSString *driveGitCommitVersion;
@property (nullable, nonatomic, copy) NSString *insightGitCommitVersion;
@property (nullable, nonatomic, copy) NSString *sentinelGitCommitVersion;
@property (nullable, nonatomic, retain) Branch *coreBranch;
@property (nullable, nonatomic, retain) Branch *sentinelBranch;
@property (nullable, nonatomic, retain) Branch *dapiBranch;
@property (nullable, nonatomic, retain) Branch *driveBranch;
@property (nullable, nonatomic, retain) Branch *insightBranch;
@property (nullable, nonatomic, retain) NSSet<Message *> *messages;

@end

@interface Masternode (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Message *)value;
- (void)removeMessagesObject:(Message *)value;
- (void)addMessages:(NSSet<Message *> *)values;
- (void)removeMessages:(NSSet<Message *> *)values;

@end

NS_ASSUME_NONNULL_END
