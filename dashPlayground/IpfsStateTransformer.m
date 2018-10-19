//
//  IpfsStateTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/14/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "IpfsStateTransformer.h"

@implementation IpfsStateTransformer

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
    DPIpfsState state = [value integerValue];
    NSString * extraInformation = @"";
    if (state & DPIpfsState_Error) {
        extraInformation = @" (Error)";
    }
    if (state & DPIpfsState_Checking) {
        extraInformation = @" (Checking)";
    }
    state = state & ~(DPIpfsState_Error | DPIpfsState_Checking);
    
    if (state & DPIpfsState_Running) {
        return [NSString stringWithFormat:@"Running%@",extraInformation];
    } else if (state & DPIpfsState_Configured) {
        return [NSString stringWithFormat:@"Configured%@",extraInformation];
    } else if (state & DPIpfsState_Installed) {
        return [NSString stringWithFormat:@"Installed%@",extraInformation];
    } else {
        return [NSString stringWithFormat:@"Initial%@",extraInformation];
    }
}

@end
