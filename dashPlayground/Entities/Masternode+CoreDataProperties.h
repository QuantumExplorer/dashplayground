//
//  Masternode+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Masternode+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Masternode (CoreDataProperties)

+ (NSFetchRequest<Masternode *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *chainNetwork;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nonatomic) int32_t currentLogLine;
@property (nonatomic) int16_t dapiState;
@property (nonatomic) int16_t dashDriveState;
@property (nullable, nonatomic, copy) NSDate *debugLastFetched;
@property (nonatomic) int32_t debugLineCount;
@property (nonatomic) int64_t lastKnownHeight;
@property (nullable, nonatomic, copy) NSString *debugOutput;
@property (nullable, nonatomic, copy) NSString *gitBranch;
@property (nullable, nonatomic, copy) NSString *gitCommit;
@property (nullable, nonatomic, copy) NSString *instanceId;
@property (nonatomic) int16_t instanceState;
@property (nonatomic) int16_t instanceType;
@property (nonatomic) BOOL isSelected;
@property (nullable, nonatomic, copy) NSString *key;
@property (nonatomic) int16_t masternodeState;
@property (nonatomic) float operationPercentageDone;
@property (nullable, nonatomic, copy) NSString *publicIP;
@property (nullable, nonatomic, copy) NSString *repositoryUrl;
@property (nullable, nonatomic, copy) NSString *rpcPassword;
@property (nullable, nonatomic, copy) NSString *sentinelGitBranch;
@property (nullable, nonatomic, copy) NSString *sentinelGitCommit;
@property (nonatomic) int16_t sentinelState;
@property (nullable, nonatomic, copy) NSString *sentinelUrl;
@property (nullable, nonatomic, copy) NSString *sentinelVersion;
@property (nonatomic) int16_t syncStatus;
@property (nullable, nonatomic, copy) NSString *transactionId;
@property (nonatomic) int16_t transactionOutputIndex;
@property (nullable, nonatomic, copy) NSString *version;
@property (nullable, nonatomic, retain) Branch *branch;
@property (nullable, nonatomic, retain) Branch *sentinelBranch;

@end

NS_ASSUME_NONNULL_END
