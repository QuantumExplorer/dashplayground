//
//  ViewController.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "DPTableView.h"

@interface RepositoriesViewController : NSViewController  <DPTableViewDelegate>

@property (readonly, strong, nonatomic) AppDelegate *appDelegate;

@property (nonatomic,strong) IBOutlet NSTextField * startCountField;

- (IBAction)pressStartIntances:(id)sender;
- (IBAction)refreshBranch:(id)sender;

@end

