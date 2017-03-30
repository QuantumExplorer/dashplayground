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
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation MasternodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)retreiveInstances:(id)sender {
    [[DPMasternodeController sharedInstance] getInstances];

}

- (IBAction)sshIn:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] sshIn:[object valueForKey:@"publicIP"]];
}

- (IBAction)stopInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"]];
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

@end
