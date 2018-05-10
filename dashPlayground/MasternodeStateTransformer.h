//
//  MasternodeStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,MasternodeState) {
    MasternodeState_Initial = 0,
    MasternodeState_Checking = 1,
    MasternodeState_Installed = 2,
    MasternodeState_Configured = 3,
    MasternodeState_Running = 4,
    MasternodeState_Error = 5,
    MasternodeState_SettingUp = 6
};

@interface MasternodeStateTransformer : NSValueTransformer

@end
