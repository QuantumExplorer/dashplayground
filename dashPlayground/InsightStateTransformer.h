//
//  InsightStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/9/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,DPInsightState) {
    DPInsightState_Initial = 0,
    DPInsightState_Checking = 1 << 0,
    DPInsightState_Cloned = 1 << 1,
    DPInsightState_Configured = 1 << 2,
    DPInsightState_Installed = 1 << 3,
    DPInsightState_Running = 1 << 4,
    DPInsightState_Error = 1 << 5,
};

@interface InsightStateTransformer : NSValueTransformer

@end


NS_ASSUME_NONNULL_END
