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
    DPRepositoryProject_Core = 0,
    DPRepositoryProject_Dapi = 1,
    DPRepositoryProject_Drive = 2,
    DPRepositoryProject_Insight = 3,
    DPRepositoryProject_Sentinel = 4
};

NS_ASSUME_NONNULL_BEGIN

@interface ProjectTypeTransformer : NSValueTransformer

@end

NS_ASSUME_NONNULL_END
