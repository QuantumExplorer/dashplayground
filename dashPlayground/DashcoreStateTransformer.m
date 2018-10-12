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

- (id)transformedValue:(id)value {
    DPDashcoreState state = [value integerValue];
    NSString * extraInformation = @"";
    if (state && (!(state & DPDashcoreState_Running)) && (state & DPDashcoreState_Configured)) {
        extraInformation = @" (Stopped)";
    }
    if (state & DPDashcoreState_Error) {
        extraInformation = @" (Error)";
    }
    if (state & DPDashcoreState_Checking) {
        extraInformation = @" (Checking)";
    }
    
    state = state & ~(DPDashcoreState_Error | DPDashcoreState_Checking);
    if (state & DPDashcoreState_Running) {
        return [NSString stringWithFormat:@"Running%@",extraInformation];
    } else if (state & DPDashcoreState_Installed) {
        return [NSString stringWithFormat:@"Installed%@",extraInformation];
    } else if (state & DPDashcoreState_Configured) {
        return [NSString stringWithFormat:@"Configured%@",extraInformation];
    } else if (state & DPDashcoreState_SettingUp) {
        return [NSString stringWithFormat:@"Setting up%@",extraInformation];
    } else {
        return [NSString stringWithFormat:@"Initial%@",extraInformation];
    }
}

@end
