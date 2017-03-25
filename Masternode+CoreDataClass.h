//
//  Masternode+CoreDataClass.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//  This file was automatically generated and should not be edited.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum INSTANCE_STATE {
    INSTANCE_STATE_stopped = 0,
    INSTANCE_STATE_running = 1
} INSTANCE_STATE;

typedef enum MASTERNODE_STATE {
    MASTERNODE_STATE_stopped = 0,
    MASTERNODE_STATE_running = 1
} MASTERNODE_STATE;

@interface Masternode : NSManagedObject

@end

NS_ASSUME_NONNULL_END

#import "Masternode+CoreDataProperties.h"
