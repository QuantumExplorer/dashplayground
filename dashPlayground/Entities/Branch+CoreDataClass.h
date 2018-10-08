//
//  Branch+CoreDataClass.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Commit, Masternode, Repository;

NS_ASSUME_NONNULL_BEGIN

@interface Branch : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Branch+CoreDataProperties.h"
