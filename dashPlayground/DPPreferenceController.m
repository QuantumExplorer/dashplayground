//
//  DPPreferenceController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 2/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DPPreferenceController.h"
#import "DPMasternodeController.h"

@implementation DPPreferenceController



#pragma mark - Singleton methods

+ (DPPreferenceController *)sharedInstance
{
    static DPPreferenceController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPPreferenceController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
