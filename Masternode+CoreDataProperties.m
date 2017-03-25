//
//  Masternode+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "Masternode+CoreDataProperties.h"

@implementation Masternode (CoreDataProperties)

+ (NSFetchRequest<Masternode *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Masternode"];
}

@dynamic publicIP;
@dynamic createdAt;
@dynamic version;
@dynamic gitCommit;
@dynamic instanceId;
@dynamic instanceState;
@dynamic masternodeState;

@end
