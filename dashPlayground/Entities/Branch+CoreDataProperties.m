//
//  Branch+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Branch+CoreDataProperties.h"

@implementation Branch (CoreDataProperties)

+ (NSFetchRequest<Branch *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Branch"];
}

@dynamic amiId;
@dynamic lastCommitSha;
@dynamic name;
@dynamic masternodes;
@dynamic repository;
@dynamic sentinels;

@end
