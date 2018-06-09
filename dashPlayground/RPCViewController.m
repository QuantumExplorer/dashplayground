//
//  RPCViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "RPCViewController.h"
#import "DPLocalNodeController.h"
#import "DialogAlert.h"
#import "DPDataStore.h"

@interface RPCViewController ()

@end

@implementation RPCViewController

-(void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)runCommand:(id)sender {
    self.terminalOutput.string = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[self.commandField stringValue] forChain:[[DPDataStore sharedInstance] chainNetwork]];
    
}
- (IBAction)checkServer:(id)sender {
    if (![[DPLocalNodeController sharedInstance] dashDPath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"dashd" exPath:@"~/Documents/src/dash/src"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [[DPLocalNodeController sharedInstance] setDashDPath:pathString];
            [self checkServer:sender];
        }
    }
    else{
        [[DPLocalNodeController sharedInstance] checkDash:^(BOOL active) {
            if (active) {
                self.serverStatusLabel.stringValue = @"Dashd running successfully";
                self.startStopButton.title = @"Stop";
            } else {
                self.serverStatusLabel.stringValue = @"Dashd isn't running";
                self.startStopButton.title = @"Start";
            }
        } forChain:[[DPDataStore sharedInstance] chainNetwork]];
    }
}

- (IBAction)startServer:(id)sender {
    if (![[DPLocalNodeController sharedInstance] dashCliPath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"dash-cli" exPath:@"~/Documents/src/dash/src"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [[DPLocalNodeController sharedInstance] setDashCliPath:pathString];
            [self startServer:sender];
        }
    }
    else {
        if ([self.startStopButton.title isEqualToString:@"Stop"]) {
            [[DPLocalNodeController sharedInstance] stopDash:^(BOOL success, NSString *message) {
                self.serverStatusLabel.stringValue = message;
                if (success) {
                    self.startStopButton.title = @"Start";
                }
            } forChain:[[DPDataStore sharedInstance] chainNetwork]];
        } else if (![[DPLocalNodeController sharedInstance] dashDPath]) {
            DialogAlert *dialog=[[DialogAlert alloc]init];
            NSAlert *findPathAlert = [dialog getFindPathAlert:@"dashd" exPath:@"~/Documents/src/dash/src"];
            
            if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
                //Find clicked
                NSString *pathString = [dialog getLaunchPath];
                [[DPLocalNodeController sharedInstance] setDashDPath:pathString];
                [self startServer:sender];
            }
        } else {
        [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
            self.serverStatusLabel.stringValue = message;
            if (success) {
                self.startStopButton.title = @"Stop";
            }
        } forChain:[[DPDataStore sharedInstance] chainNetwork]];
        }
    }
}
@end
