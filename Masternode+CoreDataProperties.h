//
//  Masternode+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import "Masternode+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Masternode (CoreDataProperties)

+ (NSFetchRequest<Masternode *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *publicIP;
@property (nullable, nonatomic, copy) NSDate *createdAt;
@property (nullable, nonatomic, copy) NSString *version;
@property (nullable, nonatomic, copy) NSString *gitCommit;
@property (nullable, nonatomic, copy) NSString *instanceId;
@property (nonatomic) int16_t instanceState;
@property (nonatomic) int16_t masternodeState;

@end

NS_ASSUME_NONNULL_END
