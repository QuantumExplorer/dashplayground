//
//  Commit+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Commit+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Commit (CoreDataProperties)

+ (NSFetchRequest<Commit *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *date;
@property (nullable, nonatomic, copy) NSString *commitHash;
@property (nullable, nonatomic, retain) Branch *branch;

@end

NS_ASSUME_NONNULL_END
