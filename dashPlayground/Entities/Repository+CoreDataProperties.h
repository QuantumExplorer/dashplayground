//
//  Repository+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Repository+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Repository (CoreDataProperties)

+ (NSFetchRequest<Repository *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *url;
@property (nonatomic) int16_t project;
@property (nonatomic) int16_t availability;
@property (nullable, nonatomic, retain) NSSet<Branch *> *branches;

@end

@interface Repository (CoreDataGeneratedAccessors)

- (void)addBranchesObject:(Branch *)value;
- (void)removeBranchesObject:(Branch *)value;
- (void)addBranches:(NSSet<Branch *> *)values;
- (void)removeBranches:(NSSet<Branch *> *)values;

@end

NS_ASSUME_NONNULL_END
