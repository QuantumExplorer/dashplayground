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

-(NSUInteger)typeForTypeName:(NSString*)string {
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
            
        default:
            return @"unknown";
            break;
    }
}



@end
