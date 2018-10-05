//
//  Message+CoreDataProperties.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Message+CoreDataProperties.h"

@implementation Message (CoreDataProperties)

+ (NSFetchRequest<Message *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Message"];
}

@dynamic atLine;
@dynamic type;
@dynamic masternode;

@end
