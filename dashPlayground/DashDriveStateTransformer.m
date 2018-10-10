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
    DPDriveState state = [value integerValue];
    NSString * extraInformation = @"";
    if (state & DPDriveState_Error) {
        extraInformation = @" (Error)";
    }
    if (state & DPDriveState_Checking) {
        extraInformation = @" (Checking)";
    }
    state = state & ~(DPDriveState_Error | DPDriveState_Checking);
    switch (state) {
        case DPDriveState_Initial:
            return [NSString stringWithFormat:@"Initial%@",extraInformation];
            break;
        case DPDriveState_Configured:
            return [NSString stringWithFormat:@"Configured%@",extraInformation];;
            break;
        case DPDriveState_Installed:
            return [NSString stringWithFormat:@"Installed%@",extraInformation];
            break;
        case DPDriveState_Running:
            return [NSString stringWithFormat:@"Running%@",extraInformation];
            break;
        case DPDriveState_Error:
            return [NSString stringWithFormat:@"Error%@",extraInformation];
            break;
        default:
            return [NSString stringWithFormat:@"Unknown%@",extraInformation];
            break;
    }
}


@end
