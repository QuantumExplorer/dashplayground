//
//  Masternode+CoreDataClass.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ProjectTypeTransformer.h"

@class Branch, Message;

NS_ASSUME_NONNULL_BEGIN

@interface Masternode : NSManagedObject

-(Branch*)branchForProject:(DPRepositoryProject)project;

@end

NS_ASSUME_NONNULL_END

#import "Masternode+CoreDataProperties.h"
