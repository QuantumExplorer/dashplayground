//
//  DAPIStateTransformer.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DAPIStateTransformer.h"

@implementation DAPIStateTransformer

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
    DPDapiState state = [value integerValue];
    NSString * extraInformation = @"";
    if (state & DPDapiState_Error) {
        extraInformation = @" (Error)";
    }
    if (state & DPDapiState_Checking) {
        extraInformation = @" (Checking)";
    }
    state = state & ~(DPDapiState_Error | DPDapiState_Checking);
    if (state & DPDapiState_Running) {
        return [NSString stringWithFormat:@"Running%@",extraInformation];
    } else if (state & DPDapiState_Installed) {
        return [NSString stringWithFormat:@"Installed%@",extraInformation];
    } else if (state & DPDapiState_Configured) {
        return [NSString stringWithFormat:@"Configured%@",extraInformation];
    } else if (state & DPDapiState_Cloned) {
        return [NSString stringWithFormat:@"Cloned%@",extraInformation];
    } else {
        return [NSString stringWithFormat:@"Initial%@",extraInformation];
    }
}

@end
