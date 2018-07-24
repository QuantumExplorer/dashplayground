//
//  NetworkViewController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 25/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "DPTableView.h"

@interface NetworkViewController : NSViewController <DPTableViewDelegate,NSTabViewDelegate>

@property (readonly, strong, nonatomic) AppDelegate *appDelegate;

@end
