//
//  MasternodeStateTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DashcoreStateTransformer.h"

@implementation DashcoreStateTransformer

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
        case DashcoreState_Initial:
            return @"Initial";
            break;
        case DashcoreState_Checking:
            return @"Checking";
            break;
        case DashcoreState_Installed:
            return @"Installed";
            break;
        case DashcoreState_Configured:
            return @"Configured";
            break;
        case DashcoreState_Running:
            return @"Running";
            break;
        case DashcoreState_Error:
            return @"Error";
            break;
        case DashcoreState_SettingUp:
            return @"Setting up";
            break;
        case DashcoreState_Stopped:
            return @"Stopped";
            break;
        default:
            return @"Unknown";
            break;
    }
}

@end
