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
    switch (state) {
        case DPDapiState_Initial:
            return [NSString stringWithFormat:@"Initial%@",extraInformation];
            break;
        case DPDapiState_Configured:
            return [NSString stringWithFormat:@"Configured%@",extraInformation];;
            break;
        case DPDapiState_Installed:
            return [NSString stringWithFormat:@"Installed%@",extraInformation];
            break;
        case DPDapiState_Running:
            return [NSString stringWithFormat:@"Running%@",extraInformation];
            break;
        case DPDapiState_Error:
            return [NSString stringWithFormat:@"Error%@",extraInformation];
            break;
        default:
            return [NSString stringWithFormat:@"Unknown%@",extraInformation];
            break;
    }
}

@end
