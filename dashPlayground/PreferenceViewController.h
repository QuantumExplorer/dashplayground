//
//  ContainerViewController.h
//  dashPlayground
//
//  Created by Nattapon Aiemlaor on 25/4/2018.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DPTableView.h"

@interface PreferenceViewController : NSWindowController <NSTableViewDataSource,NSApplicationDelegate> {}

//@property (nonatomic, strong) PreferenceViewController *windowController;
//@property(readwrite,strong)NSWindowController *windowController;


- (IBAction)createSecurityGroup:(id)sender;

- (void)showConfiguringWindow;

@end
