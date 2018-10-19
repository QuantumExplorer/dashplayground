//
//  IpfsStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/14/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,DPIpfsState) {
    DPIpfsState_Initial = 0,
    DPIpfsState_Checking = 1 << 0,
    DPIpfsState_Configured = 1 << 2,
    DPIpfsState_Installed = 1 << 3,
    DPIpfsState_Running = 1 << 4,
    DPIpfsState_Error = 1 << 5,
};

@interface IpfsStateTransformer : NSValueTransformer

@end


NS_ASSUME_NONNULL_END
