//
//  InstanceStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/29/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#define InstanceState_Transitional(x) (x == InstanceState_Pending || x == InstanceState_Stopping || x == InstanceState_Rebooting || x == InstanceState_Shutting_Down)

typedef enum InstanceState {
    InstanceState_Unknown = -1,
    InstanceState_Stopped = 0,
    InstanceState_Running = 1,
    InstanceState_Terminated = 2,
    InstanceState_Pending = 3,
    InstanceState_Stopping = 4,
    InstanceState_Rebooting = 5,
    InstanceState_Shutting_Down = 6,
} InstanceState;

typedef void (^dashStateClb)(BOOL success,InstanceState state,NSString * message);

@interface InstanceStateTransformer : NSValueTransformer

@end
