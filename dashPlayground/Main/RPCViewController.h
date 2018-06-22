//
//  RPCViewController.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CKLinkedList.h"

@interface RPCViewController : NSViewController <NSTextFieldDelegate>

@property (nonatomic) NSMutableArray *commandHistoryArray;
@property (nonatomic) int currentCommandIndex;

@property (strong) IBOutlet NSTextField *commandField;
- (IBAction)runCommand:(id)sender;
@property (strong) IBOutlet NSTextView *terminalOutput;
@property (strong) IBOutlet NSTextField *serverStatusLabel;
- (IBAction)checkServer:(id)sender;
- (IBAction)startServer:(id)sender;
@property (strong) IBOutlet NSButton *startStopButton;
@end
