//
//  Commit+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Commit+CoreDataProperties.h"

@implementation Commit (CoreDataProperties)

+ (NSFetchRequest<Commit *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Commit"];
}

@dynamic date;
@dynamic commitHash;
@dynamic branch;

@end
