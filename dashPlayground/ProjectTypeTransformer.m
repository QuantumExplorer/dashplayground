//
//  ProjectTypeTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "ProjectTypeTransformer.h"

@implementation ProjectTypeTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

+(DPRepositoryProject)typeForTypeName:(NSString*)string {
    NSString * lowercaseString = [string lowercaseString];
    if ([lowercaseString isEqualToString:@"core"]) {
        return DPRepositoryProject_Core;
    } else if ([string isEqualToString:@"dapi"]) {
        return DPRepositoryProject_Dapi;
    } else if ([string isEqualToString:@"drive"]) {
        return DPRepositoryProject_Drive;
    } else if ([string isEqualToString:@"insight"]) {
        return DPRepositoryProject_Insight;
    } else if ([string isEqualToString:@"sentinel"]) {
        return DPRepositoryProject_Sentinel;
    } else if ([string isEqualToString:@"all"]) {
        return DPRepositoryProject_All;
    }
    return DPRepositoryProject_Unknown;
}

+(NSString*)directoryForProject:(NSInteger)project {
    switch (project) {
        case DPRepositoryProject_Core:
            return @"dash";
            break;
        case DPRepositoryProject_Dapi:
            return @"dapi";
            break;
        case DPRepositoryProject_Drive:
            return @"dashdrive";
            break;
        case DPRepositoryProject_Insight:
            return @"dashcore-node";
            break;
        case DPRepositoryProject_Sentinel:
            return @"sentinel";
            break;
        default:
            return @"unknown";
            break;
    }
}

+(NSString*)developBranchForProject:(NSInteger)project {
    switch (project) {
        case DPRepositoryProject_Core:
            return @"evo";
            break;
        case DPRepositoryProject_Dapi:
            return @"develop";
            break;
        case DPRepositoryProject_Drive:
            return @"master";
            break;
        case DPRepositoryProject_Insight:
            return @"develop";
            break;
        case DPRepositoryProject_Sentinel:
            return @"master";
            break;
        default:
            return @"master";
            break;
    }
}

+(NSString*)directoryForProjectName:(NSString*)string {
    return [self directoryForProject:[self typeForTypeName:string]];
}

- (id)transformedValue:(id)value
{
    switch ([value integerValue]) {
        case DPRepositoryProject_Core:
            return @"Core";
            break;
        case DPRepositoryProject_Dapi:
            return @"Dapi";
            break;
        case DPRepositoryProject_Drive:
            return @"Drive";
            break;
        case DPRepositoryProject_Insight:
            return @"Insight";
            break;
        case DPRepositoryProject_Sentinel:
            return @"Sentinel";
            break;
        case DPRepositoryProject_All:
            return @"All";
            break;
        default:
            return @"unknown";
            break;
    }
}



@end
