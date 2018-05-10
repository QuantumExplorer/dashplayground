//
//  RepositoriesModalViewController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 3/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "MasternodesViewController.h"

@interface RepositoriesModalViewController : NSWindowController

-(void)showRepoWindow:(NSManagedObject*)object controller:(MasternodesViewController*)controller;

@end
