//
//  InsightStateTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/17/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "InsightStateTransformer.h"

@implementation InsightStateTransformer

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
    DPInsightState state = [value integerValue];
    NSString * extraInformation = @"";
    if (state & DPInsightState_Error) {
        extraInformation = @" (Error)";
    }
    if (state & DPInsightState_Checking) {
        extraInformation = @" (Checking)";
    }
    state = state & ~(DPInsightState_Error | DPInsightState_Checking);
    switch (state) {
        case DPInsightState_Initial:
            return [NSString stringWithFormat:@"Initial%@",extraInformation];
            break;
        case DPInsightState_Configured:
            return [NSString stringWithFormat:@"Configured%@",extraInformation];;
            break;
        case DPInsightState_Installed:
            return [NSString stringWithFormat:@"Installed%@",extraInformation];
            break;
        case DPInsightState_Running:
            return [NSString stringWithFormat:@"Running%@",extraInformation];
            break;
        case DPInsightState_Error:
            return [NSString stringWithFormat:@"Error%@",extraInformation];
            break;
        default:
            return [NSString stringWithFormat:@"Unknown%@",extraInformation];
            break;
    }
}

@end
