//
//  SentinelStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/17/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DPSentinelState) {
    DPSentinelState_Initial = 0,
    DPSentinelState_Checking = 1 << 0,
    DPSentinelState_Installed = 1 << 1,
    DPSentinelState_Configured = 1 << 2,
    DPSentinelState_Running = 1 << 3,
    DPSentinelState_Error = 1 << 4,
};

@interface SentinelStateTransformer : NSValueTransformer

@end
