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

@interface VersioningViewController : NSViewController

@property (readonly, strong, nonatomic) AppDelegate *appDelegate;

-(void)addStringEvent:(NSString*)string;

@end
