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
#import "ConsoleEventArray.h"
#import "Defines.h"

@interface MasternodesViewController ()
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSSegmentedControl * consoleTabSegmentedControl;
@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextView;

@end

@implementation MasternodesViewController

-(void)setUpConsole {
    self.consoleEvents = [[ConsoleEventArray alloc] init];
    [self.consoleTabSegmentedControl setTrackingMode:NSSegmentSwitchTrackingSelectOne];
//    [self.consoleTabSegmentedControl setSegmentCount:self.arrayController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpConsole];
}

- (IBAction)retreiveInstances:(id)sender {
    [self addStringEvent:@"Refreshing instances."];
    [[DPMasternodeController sharedInstance] getInstancesClb:^(BOOL success, NSString *message) {
        [self addStringEvent:@"Refreshed instances."];
    }];

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
    [[DPMasternodeController sharedInstance] setUpMasternodeDashd:object clb:^(BOOL success, NSString *message) {
        if (!success) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = message;
            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
        }
    }];
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
    } else {
        [[DPMasternodeController sharedInstance] startDashd:object clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
            if (!success) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict[NSLocalizedDescriptionKey] = errorMessage;
                NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                [[NSApplication sharedApplication] presentError:error];
            }
        }];
    }

    
    
}

- (IBAction)startInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [self addStringEvent:FS(@"Starting instance %@",[object valueForKey:@"instanceId"])];
    [[DPMasternodeController sharedInstance] startInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
        [self addStringEvent:FS(@"Instance in boot up process : %@",[object valueForKey:@"instanceId"])];
    }];
}


- (IBAction)stopInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [self addStringEvent:FS(@"Trying to stop instance %@",[object valueForKey:@"instanceId"])];
    [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
        [self addStringEvent:FS(@"Stopping instance %@",[object valueForKey:@"instanceId"])];
    }];
}

- (IBAction)terminateInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [self addStringEvent:FS(@"Trying to terminate %@",[object valueForKey:@"instanceId"])];
    [[DPMasternodeController sharedInstance] terminateInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
        [self addStringEvent:FS(@"Terminating instance %@",[object valueForKey:@"instanceId"])];
    }];
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

#pragma mark Console

-(void)addStringEvent:(NSString*)string {
    ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
    [self.consoleEvents addConsoleEvent:consoleEvent];
    [self updateConsole];
}


-(void)addEvent:(ConsoleEvent*)consoleEvent {
    [self.consoleEvents addConsoleEvent:consoleEvent];
    [self updateConsole];
}

-(void)updateConsole {
    if (!self.consoleTabSegmentedControl.selectedSegment) {
        NSString * consoleEventString = [self.consoleEvents printOut];
        self.consoleTextView.string = consoleEventString;
    } else {
        NSInteger row = self.tableView.selectedRow;
        if (row == -1) return;
        NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
        self.consoleTextView.string = @"Select a running masternode";
    }
    

}

#pragma mark Console tab view delegate

- (IBAction)selectedConsoleTab:(id)sender {
    [self updateConsole];
    
    
}

@end
