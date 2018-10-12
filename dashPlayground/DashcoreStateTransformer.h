//
//  MasternodeStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DPDashcoreState) {
    DPDashcoreState_Initial = 0,
    DPDashcoreState_Checking = 1 << 0,
    DPDashcoreState_Installed = 1 << 1,
    DPDashcoreState_Configured = 1 << 2,
    DPDashcoreState_Running = 1 << 3,
    DPDashcoreState_Error = 1 << 4,
    DPDashcoreState_SettingUp = 1 << 5
};

@interface DashcoreStateTransformer : NSValueTransformer

@end
