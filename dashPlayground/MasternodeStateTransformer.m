//
//  MasternodeStateTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "MasternodeStateTransformer.h"

@implementation MasternodeStateTransformer

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
        case MasternodeState_Initial:
            return @"Initial";
            break;
        case MasternodeState_Checking:
            return @"Checking";
            break;
        case MasternodeState_Installed:
            return @"Installed";
            break;
        case MasternodeState_Configured:
            return @"Configured";
            break;
        case MasternodeState_Running:
            return @"Running";
            break;
        case MasternodeState_Error:
            return @"Error";
            break;
        default:
            return @"Unknown";
            break;
    }
}

@end
