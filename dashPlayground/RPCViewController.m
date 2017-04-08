//
//  RPCViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "RPCViewController.h"
#import "DPLocalNodeController.h"

@implementation RPCViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [self checkServer:self];
}

- (IBAction)runCommand:(id)sender {
    self.terminalOutput.string = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[self.commandField stringValue]];
    
}
- (IBAction)checkServer:(id)sender {
    [[DPLocalNodeController sharedInstance] checkDash:^(BOOL active) {
        if (active) {
            self.serverStatusLabel.stringValue = @"Dashd running successfully";
            self.startStopButton.title = @"Stop";
        } else {
            self.serverStatusLabel.stringValue = @"Dashd isn't running";
            self.startStopButton.title = @"Start";
        }
    }];
}

- (IBAction)startServer:(id)sender {
    if ([self.startStopButton.title isEqualToString:@"Stop"]) {
        [[DPLocalNodeController sharedInstance] stopDash:^(BOOL success, NSString *message) {
            self.serverStatusLabel.stringValue = message;
            if (success) {
                self.startStopButton.title = @"Start";
            }
        }];
    } else {
    [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
        self.serverStatusLabel.stringValue = message;
        if (success) {
            self.startStopButton.title = @"Stop";
        }
    }];
    }
}
@end
