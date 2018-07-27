//
//  DashDriveStateTransformer.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DashDriveStateTransformer.h"

@implementation DashDriveStateTransformer

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
        case DashDriveState_Initial:
            return @"Initial";
            break;
        case DashDriveState_Checking:
            return @"Checking";
            break;
        case DashDriveState_Installed:
            return @"Installed";
            break;
        case DashDriveState_Running:
            return @"Running";
            break;
        case DashDriveState_Error:
            return @"Error";
            break;
        default:
            return @"Unknown";
            break;
    }
}

@end
