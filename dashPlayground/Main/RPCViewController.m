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

@synthesize commandHistoryArray;
@synthesize currentCommandIndex;

-(void)viewDidLoad {
    [super viewDidLoad];
    self.commandField.delegate = self;
    commandHistoryArray = [NSMutableArray array];
    currentCommandIndex = 999;
}

- (IBAction)runCommand:(id)sender {
    self.terminalOutput.string = @"";
    [commandHistoryArray addObject:self.commandField.stringValue];
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[self.commandField stringValue] forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
    self.commandField.stringValue = @"";
    currentCommandIndex = 999;
//    self.terminalOutput.string = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[self.commandField stringValue] forChain:[[DPDataStore sharedInstance] chainNetwork]];
    
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

- (IBAction)pressGetInfo:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getinfo" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (IBAction)pressBalance:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getbalance" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (IBAction)pressMNStatus:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"mnsync status" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (IBAction)pressMNList:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"masternode list" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (IBAction)pressBlockChainInfo:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getblockchaininfo" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (IBAction)pressUnspentList:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"listunspent" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (IBAction)pressGetNodeInfo:(id)sender {
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getaddednodeinfo" forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)fieldEditor
doCommandBySelector:(SEL)commandSelector {
    
    if( commandSelector == @selector(moveUp:) ){
        if(currentCommandIndex == 999) {
            if([commandHistoryArray count] == 0) return NO;
            self.commandField.stringValue = [commandHistoryArray lastObject];
            currentCommandIndex = (int)[commandHistoryArray count]-1;
        }
        else {
            if(currentCommandIndex != 0) currentCommandIndex = currentCommandIndex-1;
            if(currentCommandIndex < 0 || currentCommandIndex > [commandHistoryArray count]-1) return NO;
            self.commandField.stringValue = [commandHistoryArray objectAtIndex:currentCommandIndex];
        }
        return YES;    // We handled this command; don't pass it on
    }
    else if( commandSelector == @selector(moveDown:) ){
        if(currentCommandIndex != 999) {
            if(currentCommandIndex < [commandHistoryArray count]-1) currentCommandIndex = currentCommandIndex+1;
            if(currentCommandIndex < 0 || currentCommandIndex > [commandHistoryArray count]-1) return NO;
            self.commandField.stringValue = [commandHistoryArray objectAtIndex:currentCommandIndex];
        }
        return YES;
    }
    
    return NO;    // Default handling of the command
    
}

- (IBAction)pressCommandField:(id)sender {
    
    if([self.commandField stringValue].length == 0) return;
    [commandHistoryArray addObject:self.commandField.stringValue];
    
    self.terminalOutput.string = @"";
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[self.commandField stringValue] forChain:[[DPDataStore sharedInstance] chainNetwork] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSMutableString  *newString = [[NSMutableString alloc] init];
            [newString appendString:[NSString stringWithFormat:@"%@", self.terminalOutput.string]];
            [newString appendString:message];
            self.terminalOutput.string = newString;
        });
    }];
    self.commandField.stringValue = @"";
    currentCommandIndex = 999;
}

@end
