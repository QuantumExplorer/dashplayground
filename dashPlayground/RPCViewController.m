//
//  RPCViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/3/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "RPCViewController.h"
#import "DPMasternodeController.h"

@implementation RPCViewController

- (IBAction)runCommand:(id)sender {
    self.terminalOutput.string = [[DPMasternodeController sharedInstance] runDashRPCCommandString:[self.commandField stringValue]];
    
}
@end
