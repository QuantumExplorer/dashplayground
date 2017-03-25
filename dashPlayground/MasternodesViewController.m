//
//  MasternodesViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "MasternodesViewController.h"
#import "DPMasternodeController.h"

@interface MasternodesViewController ()
@property (strong) IBOutlet NSArrayController *arrayController;

@end

@implementation MasternodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)retreiveInstances:(id)sender {
    [[DPMasternodeController sharedInstance] getInstances];

}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

@end
