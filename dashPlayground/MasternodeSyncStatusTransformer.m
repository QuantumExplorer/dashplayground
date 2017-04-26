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

+(NSUInteger)typeForTypeName:(NSString*)string {
    if ([string isEqualToString:@"MASTERNODE_SYNC_INITIAL"]) {
        return MasternodeSync_Initial;
    } else if ([string isEqualToString:@"MASTERNODE_SYNC_SPORKS"]) {
        return MasternodeSync_Sporks;
    } else if ([string isEqualToString:@"MASTERNODE_SYNC_LIST"]) {
        return MasternodeSync_List;
    } else if ([string isEqualToString:@"MASTERNODE_SYNC_MNW"]) {
        return MasternodeSync_MNW;
    } else if ([string isEqualToString:@"MASTERNODE_SYNC_GOVERNANCE"]) {
        return MasternodeSync_Governance;
    } else if ([string isEqualToString:@"MASTERNODE_SYNC_FAILED"]) {
        return MasternodeSync_Failed;
    } else if ([string isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
        return MasternodeSync_Finished;
    }
    return MasternodeSync_Initial;
}

+(NSString*)typeNameForType:(NSUInteger)type {
    switch (type) {
        case MasternodeSync_Initial:
            return @"MASTERNODE_SYNC_INITIAL";
            break;
        case MasternodeSync_Sporks:
            return @"MASTERNODE_SYNC_SPORKS";
            break;
        case MasternodeSync_List:
            return @"MASTERNODE_SYNC_LIST";
            break;
        case MasternodeSync_MNW:
            return @"MASTERNODE_SYNC_MNW";
            break;
        case MasternodeSync_Governance:
            return @"MASTERNODE_SYNC_GOVERNANCE";
            break;
        case MasternodeSync_Failed:
            return @"MASTERNODE_SYNC_FAILED";
            break;
        case MasternodeSync_Finished:
            return @"MASTERNODE_SYNC_FINISHED";
            break;
        default:
            return @"MASTERNODE_SYNC_INITIAL";
            break;
    }
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
