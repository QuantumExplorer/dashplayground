//
//  DAPIStateTransformer.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger,DPDapiState) {
    DPDapiState_Initial = 0,
    DPDapiState_Checking = 1 << 0,
    DPDapiState_Installed = 1 << 1,
    DPDapiState_Configured = 1 << 2,
    DPDapiState_Running = 1 << 3,
    DPDapiState_Error = 1 << 4,
};

@interface DAPIStateTransformer : NSValueTransformer

@end
