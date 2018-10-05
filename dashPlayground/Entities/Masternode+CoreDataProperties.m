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
@dynamic gitBranch;
@dynamic gitCommit;
@dynamic instanceId;
@dynamic instanceState;
@dynamic instanceType;
@dynamic isSelected;
@dynamic key;
@dynamic masternodeState;
@dynamic operationPercentageDone;
@dynamic publicIP;
@dynamic repositoryUrl;
@dynamic rpcPassword;
@dynamic sentinelGitBranch;
@dynamic sentinelGitCommit;
@dynamic sentinelState;
@dynamic sentinelUrl;
@dynamic sentinelVersion;
@dynamic syncStatus;
@dynamic transactionId;
@dynamic transactionOutputIndex;
@dynamic version;
@dynamic branch;
@dynamic sentinelBranch;
@dynamic lastKnownHeight;

@end
