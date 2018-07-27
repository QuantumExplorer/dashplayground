//
//  DAPIStateTransformer.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,SentinelState) {
    DAPIState_Initial = 0,
    DAPIState_Checking = 1,
    DAPIState_Installed = 2,
    DAPIState_Running = 4,
    DAPIState_Error = 5
};

@interface DAPIStateTransformer : NSValueTransformer

@end
