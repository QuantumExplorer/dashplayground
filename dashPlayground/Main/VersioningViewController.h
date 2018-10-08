//
//  VersioningViewController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "DPTableView.h"
#import "DPVersioningController.h"

@protocol DPVersionControllerDelegate;

@interface VersioningViewController : NSViewController <DPVersionControllerDelegate>

-(void)addStringEvent:(NSString*)string;

@end
