//
//  Message+CoreDataProperties.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Message+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Message (CoreDataProperties)

+ (NSFetchRequest<Message *> *)fetchRequest;

@property (nonatomic) int16_t atLine;
@property (nonatomic) int16_t type;
@property (nullable, nonatomic, retain) Masternode *masternode;

@end

NS_ASSUME_NONNULL_END
