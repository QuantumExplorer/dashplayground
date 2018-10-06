//
//  MasternodeStateTransformer.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/7/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DashcoreState) {
    DashcoreState_Initial = 0,
    DashcoreState_Checking = 1,
    DashcoreState_Installed = 2,
    DashcoreState_Configured = 3,
    DashcoreState_Running = 4,
    DashcoreState_Error = 5,
    DashcoreState_SettingUp = 6,
    DashcoreState_Stopped = 7
};

@interface DashcoreStateTransformer : NSValueTransformer

@end
