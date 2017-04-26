//
//  MasternodeSyncStatusTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,MasternodeSync) {
    MasternodeSync_Initial = 0,
    MasternodeSync_Sporks = 1,
    MasternodeSync_List = 2,
    MasternodeSync_MNW = 3,
    MasternodeSync_Governance = 4,
    MasternodeSync_Failed = 5,
    MasternodeSync_Finished = 6,
};


@interface MasternodeSyncStatusTransformer : NSValueTransformer

+(NSUInteger)typeForTypeName:(NSString*)string;
+(NSString*)typeNameForType:(NSUInteger)type;

@end
