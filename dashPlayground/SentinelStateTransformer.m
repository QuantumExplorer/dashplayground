//
//  SentinelStateTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/17/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "SentinelStateTransformer.h"

@implementation SentinelStateTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    DPSentinelState state = [value integerValue];
    NSString * extraInformation = @"";
    if (state & DPSentinelState_Error) {
        extraInformation = @" (Error)";
    }
    if (state & DPSentinelState_Checking) {
        extraInformation = @" (Checking)";
    }
    state = state & ~(DPSentinelState_Error | DPSentinelState_Checking);
    if (state & DPSentinelState_Running) {
        return [NSString stringWithFormat:@"Running%@",extraInformation];
    } else if (state & DPSentinelState_Installed) {
        return [NSString stringWithFormat:@"Installed%@",extraInformation];
    } else if (state & DPSentinelState_Configured) {
        return [NSString stringWithFormat:@"Configured%@",extraInformation];
    } else if (state & DPSentinelState_Cloned) {
        return [NSString stringWithFormat:@"Cloned%@",extraInformation];
    } else {
        return [NSString stringWithFormat:@"Initial%@",extraInformation];
    }
}

@end
