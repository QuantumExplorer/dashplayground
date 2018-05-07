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
#import "DialogAlert.h"
#import "VolumeViewController.h"
#import "RepositoriesModalViewController.h"
#import "MasternodeStateTransformer.h"

@interface MasternodesViewController ()
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSSegmentedControl * consoleTabSegmentedControl;
@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextView;

//Masternode control
@property (strong) IBOutlet NSButton *setupButton;
@property (strong) ConsoleEventArray * masternodeConsoleEvents;

//Instance control
@property (strong) IBOutlet NSButton *startInstanceButton;

//Terminal
@property (strong) ConsoleEventArray * terminalConsoleEvents;

@end

@implementation MasternodesViewController

NSString *terminalString = @"";

@synthesize consoleTabSegmentedControl;

-(void)setUpConsole {
    self.consoleEvents = [[ConsoleEventArray alloc] init];
    self.terminalConsoleEvents = [[ConsoleEventArray alloc] init];
    self.masternodeConsoleEvents = [[ConsoleEventArray alloc] init];
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
    
    RepositoriesModalViewController *repoController = [[RepositoriesModalViewController alloc] init];
    [repoController showRepoWindow:object];
    
//    [[DPMasternodeController sharedInstance] setUpMasternodeDashd:object clb:^(BOOL success, NSString *message) {
//        if (!success) {
//            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//            dict[NSLocalizedDescriptionKey] = message;
//            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
//            [[NSApplication sharedApplication] presentError:error];
//        }
//    }];
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
    if (row == -1)
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to start instance!" message:@"Please make sure you already select an instance."];
        return;
    }
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [self addStringEvent:FS(@"Starting instance %@",[object valueForKey:@"instanceId"])];
    [[DPMasternodeController sharedInstance] startInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
        [self addStringEvent:FS(@"Instance in boot up process : %@",[object valueForKey:@"instanceId"])];
    }];
}


- (IBAction)stopInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1)
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to stop instance!" message:@"Please make sure you already select an instance."];
        return;
    }
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
    NSString *msgAlert = FS(@"Are you sure you want to stop instance id %@?", [object valueForKey:@"instanceId"]);
    
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Stop instance" message:msgAlert];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self addStringEvent:FS(@"Trying to stop instance %@",[object valueForKey:@"instanceId"])];
        [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
            [self addStringEvent:FS(@"Stopping instance %@",[object valueForKey:@"instanceId"])];
        }];
    }
}

- (IBAction)terminateInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1)
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to terminate instance!" message:@"Please make sure you already select an instance."];
        return;
    }
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
    NSString *msgAlert = FS(@"Are you sure you want to terminate instance id %@?", [object valueForKey:@"instanceId"]);
    
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Terminate instance" message:msgAlert];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self addStringEvent:FS(@"Trying to terminate %@",[object valueForKey:@"instanceId"])];
        [[DPMasternodeController sharedInstance] terminateInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
            [self addStringEvent:FS(@"Terminating instance %@",[object valueForKey:@"instanceId"])];
        }];
    }
    
}

- (IBAction)createNewInstance:(id)sender {
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Create new instance" message:@"Are you sure you want to create a new instance with initial AMI?"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self addStringEvent:FS(@"Trying to create a new instance.")];
        
        [[DPMasternodeController sharedInstance] createInstanceWithInitialAMI:^(BOOL success,InstanceState state, NSString *message) {
            if(success)
            {
                [self addStringEvent:FS(@"new instance is created succesfully.")];
            }
            else{
                [self addStringEvent:FS(@"creating new instance failure.")];
            }
        }];
    }
    else
    {
        return;
    }
    
}

- (IBAction)createAMI:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1)
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create new AMI!" message:@"Please make sure you already select an instance."];
        return;
    }
    
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    VolumeViewController *volumeController = [[VolumeViewController alloc]init];
    [volumeController showAMIWindow:[object valueForKey:@"instanceId"]];
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

-(void)addStringEventToTerminalConsole:(NSString*)string {
    ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
    [self.terminalConsoleEvents addConsoleEvent:consoleEvent];
    [self updateConsole];
}

-(void)addStringEventToMasternodeConsole:(NSString*)string {
    ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
    [self.masternodeConsoleEvents addConsoleEvent:consoleEvent];
    [self updateConsole];
}

-(void)updateConsole {
    if (!self.consoleTabSegmentedControl.selectedSegment) {
        NSString * consoleEventString = [self.consoleEvents printOut];
        self.consoleTextView.string = consoleEventString;
    } else {
        
        if(self.consoleTabSegmentedControl.selectedSegment == 1)
        {
//            NSInteger row = self.tableView.selectedRow;
//            if (row == -1) return;
//            NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//            self.consoleTextView.string = @"Select a running masternode";
            NSString * consoleEventString = [self.masternodeConsoleEvents printOut];
            self.consoleTextView.string = consoleEventString;
        }
        else if(self.consoleTabSegmentedControl.selectedSegment == 2)
        {
            NSString * consoleEventString = [self.terminalConsoleEvents printOut];
            self.consoleTextView.string = consoleEventString;
        }
    }
    

}

#pragma mark Console tab view delegate

- (IBAction)selectedConsoleTab:(id)sender {
    [self updateConsole];
}

- (IBAction)pressCommandField:(NSTextField*)string {
    NSDictionary *output = [[DPMasternodeController sharedInstance] runTerminalCommandJSON:[NSString stringWithFormat:@"%@", string.stringValue]];
    
    if([terminalString isEqualToString:@""])
    {
        [self addStringEventToTerminalConsole:[NSString stringWithFormat:@"%@", output]];
    }
    else
    {
        [self addStringEventToTerminalConsole:[NSString stringWithFormat:@"%@", terminalString]];
        terminalString = @"";
    }
}

-(void)setTerminalString:(NSString*)string {
    terminalString = string;
}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if(row == -1) {self.setupButton.enabled = false; return;}
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
    if ([[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Installed) {
        self.setupButton.enabled = false;
    }
    else{
        self.setupButton.enabled = true;
    }
}

#pragma mark - Singleton methods

+ (MasternodesViewController *)sharedInstance
{
    static MasternodesViewController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MasternodesViewController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
