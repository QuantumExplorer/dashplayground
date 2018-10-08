//
//  ProjectTypeTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DPRepositoryProject) {
    DPRepositoryProject_Unknown = NSUIntegerMax,
    DPRepositoryProject_All = NSUIntegerMax -1,
    DPRepositoryProject_Core = 0,
    DPRepositoryProject_Dapi = 1,
    DPRepositoryProject_Drive = 2,
    DPRepositoryProject_Insight = 3,
    DPRepositoryProject_Sentinel = 4,
    DPRepositoryProject_Last = DPRepositoryProject_Sentinel
};

NS_ASSUME_NONNULL_BEGIN

@interface ProjectTypeTransformer : NSValueTransformer

+(NSString*)directoryForProjectName:(NSString*)string;
+(DPRepositoryProject)typeForTypeName:(NSString*)string;
+(NSString*)directoryForProject:(NSInteger)project;
+(NSString*)developBranchForProject:(NSInteger)project;

@end

NS_ASSUME_NONNULL_END
