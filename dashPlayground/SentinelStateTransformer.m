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
    switch ([value integerValue]) {
        case SentinelState_Initial:
            return @"Initial";
            break;
        case SentinelState_Checking:
            return @"Checking";
            break;
        case SentinelState_Installed:
            return @"Installed";
            break;
        case SentinelState_Running:
            return @"Running";
            break;
        case SentinelState_Error:
            return @"Error";
            break;
        default:
            return @"Unknown";
            break;
    }
}


@end
