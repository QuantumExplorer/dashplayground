//
//  DashDriveStateTransformer.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,SentinelState) {
    DashDriveState_Initial = 0,
    DashDriveState_Checking = 1,
    DashDriveState_Installed = 2,
    DashDriveState_Running = 4,
    DashDriveState_Error = 5
};

@interface DashDriveStateTransformer : NSValueTransformer

@end
