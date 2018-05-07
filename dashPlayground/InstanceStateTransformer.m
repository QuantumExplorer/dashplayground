//
//  InstanceStateTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/29/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "InstanceStateTransformer.h"

@implementation InstanceStateTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

-(NSUInteger)stateForStateName:(NSString*)string {
    if ([string isEqualToString:@"running"]) {
        return InstanceState_Running;
    } else if ([string isEqualToString:@"pending"]) {
        return InstanceState_Pending;
    } else if ([string isEqualToString:@"stopped"]) {
        return InstanceState_Stopped;
    } else if ([string isEqualToString:@"terminated"]) {
        return InstanceState_Terminated;
    } else if ([string isEqualToString:@"stopping"]) {
        return InstanceState_Stopping;
    } else if ([string isEqualToString:@"rebooting"]) {
        return InstanceState_Rebooting;
    } else if ([string isEqualToString:@"shutting-down"]) {
        return InstanceState_Shutting_Down;
    }
    return InstanceState_Stopped;
}


- (id)transformedValue:(id)value
{
    switch ([value integerValue]) {
        case InstanceState_Running:
            return @"running";
            break;
        case InstanceState_Pending:
            return @"pending";
            break;
        case InstanceState_Stopped:
            return @"stopped";
            break;
        case InstanceState_Terminated:
            return @"terminated";
            break;
        case InstanceState_Stopping:
            return @"stopping";
            break;
        case InstanceState_Rebooting:
            return @"rebooting";
            break;
        case InstanceState_Shutting_Down:
            return @"shutting down";
            break;
        default:
            return @"stopped";
            break;
    }
}


@end
