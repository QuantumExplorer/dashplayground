//
//  Repository+CoreDataClass.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ProjectTypeTransformer.h"


@class Branch;

NS_ASSUME_NONNULL_BEGIN

@interface Repository : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Repository+CoreDataProperties.h"
