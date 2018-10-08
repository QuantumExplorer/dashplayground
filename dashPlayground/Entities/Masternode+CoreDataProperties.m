//
//  Masternode+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Masternode+CoreDataProperties.h"

@implementation Masternode (CoreDataProperties)

+ (NSFetchRequest<Masternode *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Masternode"];
}

@dynamic chainNetwork;
@dynamic createdAt;
@dynamic currentLogLine;
@dynamic dapiState;
@dynamic dashDriveState;
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
@dynamic syncStatus;
@dynamic transactionId;
@dynamic transactionOutputIndex;
@dynamic coreSemanticVersion;
@dynamic coreBranch;
@dynamic sentinelBranch;
@dynamic lastKnownHeight;
@dynamic dapiBranch;
@dynamic driveBranch;
@dynamic insightBranch;
@dynamic installedNVM;
@dynamic installedPM2;
@dynamic nodeVersion;

@end
