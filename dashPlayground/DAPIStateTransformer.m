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
    switch ([value integerValue]) {
        case DAPIState_Initial:
            return @"Initial";
            break;
        case DAPIState_Checking:
            return @"Checking";
            break;
        case DAPIState_Installed:
            return @"Installed";
            break;
        case DAPIState_Running:
            return @"Running";
            break;
        case DAPIState_Error:
            return @"Error";
            break;
        default:
            return @"Unknown";
            break;
    }
}

@end
