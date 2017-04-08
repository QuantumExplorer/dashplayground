//
//  MasternodeSyncStatusTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "MasternodeSyncStatusTransformer.h"

@implementation MasternodeSyncStatusTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

-(NSUInteger)typeForTypeName:(NSString*)string {
    if ([string isEqualToString:@"initial"]) {
        return MasternodeSync_Initial;
    } else if ([string isEqualToString:@"sporks"]) {
        return MasternodeSync_Sporks;
    } else if ([string isEqualToString:@"list"]) {
        return MasternodeSync_List;
    } else if ([string isEqualToString:@"mnw"]) {
        return MasternodeSync_MNW;
    } else if ([string isEqualToString:@"governance"]) {
        return MasternodeSync_Governance;
    } else if ([string isEqualToString:@"failes"]) {
        return MasternodeSync_Failed;
    } else if ([string isEqualToString:@"finished"]) {
        return MasternodeSync_Finished;
    }
    return MasternodeSync_Initial;
}


- (id)transformedValue:(id)value
{
    switch ([value integerValue]) {
        case MasternodeSync_Initial:
            return @"Initial";
            break;
        case MasternodeSync_Sporks:
            return @"Sporks";
            break;
        case MasternodeSync_List:
            return @"List";
            break;
        case MasternodeSync_MNW:
            return @"MNW";
            break;
        case MasternodeSync_Governance:
            return @"Governance";
            break;
        case MasternodeSync_Failed:
            return @"Failed";
            break;
        case MasternodeSync_Finished:
            return @"Finished";
            break;
        default:
            return @"unknown";
            break;
    }
}


@end
