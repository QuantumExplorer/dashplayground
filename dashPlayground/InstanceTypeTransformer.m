//
//  InstanceTypeTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/6/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "InstanceTypeTransformer.h"

@implementation InstanceTypeTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

-(NSUInteger)typeForTypeName:(NSString*)string {
    if ([string isEqualToString:@"manual"]) {
        return InstanceType_Manual;
    } else if ([string isEqualToString:@"AWS"]) {
        return InstanceType_AWS;
    }
    return InstanceType_Unknown;
}


- (id)transformedValue:(id)value
{
    switch ([value integerValue]) {
        case InstanceType_Unknown:
            return @"unknown";
            break;
        case InstanceType_Manual:
            return @"manual";
            break;
        case InstanceType_AWS:
            return @"AWS";
            break;
        default:
            return @"unknown";
            break;
    }
}


@end
