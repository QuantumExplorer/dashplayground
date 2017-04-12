//
//  MasternodesViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "MasternodesViewController.h"
#import "DPMasternodeController.h"
#import "DPLocalNodeController.h"
#import "DPDataStore.h"
#import "NSArray+SWAdditions.h"

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

- (IBAction)getKey:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    if (![object valueForKey:@"key"]) {
        NSString * key = [[[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"-testnet masternode genkey"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([key length] == 51) {
            [object setValue:key forKey:@"key"];
        }
        
        [[DPDataStore sharedInstance] saveContext];
    }
}

- (IBAction)setUp:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] setUpMasternodeDashd:object];
}

- (IBAction)configure:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] setUpMasternodeConfiguration:object clb:^(BOOL success, NSString *message) {
        if (!success) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = message;
            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
        }
    }];
}

- (IBAction)startRemote:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    if (![object valueForKey:@"key"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"You must first have a key for the masternode before you can start it.";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return;
    }
    if (![object valueForKey:@"instanceId"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"You must first have a key for the masternode before you can start it.";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return;
    }

        [[DPLocalNodeController sharedInstance] startRemote:object];
    
}

- (IBAction)startInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] startInstance:[object valueForKey:@"instanceId"]];
}


- (IBAction)stopInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"]];
}

- (IBAction)terminateInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] terminateInstance:[object valueForKey:@"instanceId"]];
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

@end
