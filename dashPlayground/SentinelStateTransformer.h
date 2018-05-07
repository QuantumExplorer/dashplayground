//
//  SentinelStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/17/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,SentinelState) {
    SentinelState_Initial = 0,
    SentinelState_Checking = 1,
    SentinelState_Installed = 2,
    SentinelState_Running = 4,
    SentinelState_Error = 5
};

@interface SentinelStateTransformer : NSValueTransformer

@end
