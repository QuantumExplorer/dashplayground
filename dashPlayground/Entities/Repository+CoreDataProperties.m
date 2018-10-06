//
//  Repository+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Repository+CoreDataProperties.h"

@implementation Repository (CoreDataProperties)

+ (NSFetchRequest<Repository *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Repository"];
}

@dynamic url;
@dynamic project;
@dynamic isPrivate;
@dynamic branches;
@dynamic owner;
@dynamic name;

@end
