//
//  MasternodesViewController.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface ConsoleEventInfo : NSObject

@property (nonatomic,strong) NSDate * startDate;
@property (nonatomic,strong) NSDate * lastInfoDate;
@property (nonatomic,strong) NSString * text;

@end

@interface MasternodesViewController : NSViewController <NSTabViewDelegate>

+(MasternodesViewController*)sharedInstance;

@property (readonly, strong, nonatomic) AppDelegate *appDelegate;

- (IBAction)retreiveInstances:(id)sender;
- (IBAction)getKey:(id)sender;

- (IBAction)setUp:(id)sender;
- (IBAction)configure:(id)sender;
- (IBAction)startRemote:(id)sender;

- (IBAction)selectedConsoleTab:(id)sender;

-(void)addStringEvent:(NSString*)string;
-(void)addStringEventToTerminalConsole:(NSString*)string;
-(void)setTerminalString:(NSString*)string;

@end
