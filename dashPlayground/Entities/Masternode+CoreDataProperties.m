//
//  Masternode+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Masternode+CoreDataProperties.h"

@implementation Masternode (CoreDataProperties)

+ (NSFetchRequest<Masternode *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Masternode"];
}

@dynamic currentLogLine;
@dynamic driveState;
@dynamic debugLastFetched;
@dynamic debugLineCount;
@dynamic debugOutput;
@dynamic coreGitCommitVersion;
@dynamic instanceId;
@dynamic instanceState;
@dynamic instanceType;
@dynamic isSelected;
@dynamic key;
@dynamic dashcoreState;
@dynamic operationPercentageDone;
@dynamic publicIP;
@dynamic repositoryUrl;
@dynamic rpcPassword;
@dynamic sentinelGitCommitVersion;
@dynamic sentinelState;
@dynamic sentinelUrl;
@dynamic sentinelVersion;
@dynamic syncStatus;
@dynamic transactionId;
@dynamic transactionOutputIndex;
@dynamic coreSemanticVersion;
@dynamic lastKnownHeight;
@dynamic chainNetwork;
@dynamic createdAt;
@dynamic dapiState;
@dynamic nodeVersion;
@dynamic installedNVM;
@dynamic installedPM2;
@dynamic dapiGitCommitVersion;
@dynamic driveGitCommitVersion;
@dynamic insightGitCommitVersion;
@dynamic coreBranch;
@dynamic sentinelBranch;
@dynamic dapiBranch;
@dynamic driveBranch;
@dynamic insightBranch;
@dynamic messages;

@end
