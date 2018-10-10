//
//  DashDriveStateTransformer.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DPDriveState) {
    DPDriveState_Initial = 0,
    DPDriveState_Checking = 1 << 0,
    DPDriveState_Installed = 1 << 1,
    DPDriveState_Configured = 1 << 2,
    DPDriveState_Running = 1 << 3,
    DPDriveState_Error = 1 << 4,
};

@interface DashDriveStateTransformer : NSValueTransformer

@end
