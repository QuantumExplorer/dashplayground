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
    if (state & DPDriveState_Running) {
        return [NSString stringWithFormat:@"Running%@",extraInformation];
    } else if (state & DPDriveState_Installed) {
        return [NSString stringWithFormat:@"Installed%@",extraInformation];
    } else if (state & DPDriveState_Configured) {
        return [NSString stringWithFormat:@"Configured%@",extraInformation];
    } else if (state & DPDriveState_Cloned) {
        return [NSString stringWithFormat:@"Cloned%@",extraInformation];
    } else {
        return [NSString stringWithFormat:@"Initial%@",extraInformation];
    }
}


@end
