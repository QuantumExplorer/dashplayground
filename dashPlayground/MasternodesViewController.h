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

@property (strong) IBOutlet NSBox *devnetBox;
+(MasternodesViewController*)sharedInstance;

@property (readonly, strong, nonatomic) AppDelegate *appDelegate;

- (IBAction)retreiveInstances:(id)sender;
- (IBAction)getKey:(id)sender;

@property (strong) IBOutlet NSButtonCell *setupButton;
- (IBAction)setUp:(id)sender;
- (IBAction)configure:(id)sender;
- (IBAction)startRemote:(id)sender;

- (IBAction)selectedConsoleTab:(id)sender;

-(void)addStringEventToMasternodeConsole:(NSString*)string;
-(void)addStringEvent:(NSString*)string;

@property (strong) IBOutlet NSSegmentedControl * consoleTabSegmentedControl;

@end
