//
//  MasternodesViewController.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface MasternodesViewController : NSViewController

@property (readonly, strong, nonatomic) AppDelegate *appDelegate;

- (IBAction)retreiveInstances:(id)sender;

- (IBAction)sshIn:(id)sender;

@end
