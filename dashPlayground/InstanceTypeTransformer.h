//
//  InstanceTypeTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/6/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum InstanceType {
    InstanceType_Unknown = 0,
    InstanceType_Manual = 1,
    InstanceType_AWS = 2
} InstanceType;

@interface InstanceTypeTransformer : NSValueTransformer

@end
