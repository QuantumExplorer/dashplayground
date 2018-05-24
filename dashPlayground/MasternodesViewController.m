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
#import "DPMasternodeController.h"
#import <NMSSH/NMSSH.h>

@interface MasternodesViewController ()

@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextView;

//Masternode control
@property (strong) IBOutlet NSButtonCell *createAmiButton;
@property (strong) ConsoleEventArray * masternodeConsoleEvents;
@property (strong) IBOutlet NSButton *connectButton;

//Instance control
@property (strong) IBOutlet NSButton *startInstanceButton;

//Terminal
@property (strong) ConsoleEventArray * terminalConsoleEvents;
@property (strong) IBOutlet NSTextField *commandTextField;

@property (strong) NMSSHSession *ssh;
@end

@implementation MasternodesViewController

MasternodesViewController *masternodeController;

NSString *terminalHeadString = @"";

@synthesize consoleTabSegmentedControl;
@synthesize ssh;

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
    masternodeController = self;
}

- (IBAction)retreiveInstances:(id)sender {
    [self addStringEvent:@"Refreshing instances."];
    [[DPMasternodeController sharedInstance] getInstancesClb:^(BOOL success, NSString *message) {
        [self addStringEvent:@"Refreshed instances."];
    }];

}

- (IBAction)connectInstance:(id)sender {
    
    if ([self.connectButton.title isEqualToString:@"Disconnect"]) {
        [self.ssh disconnect];
        self.connectButton.title = @"Connect";
        [self addStringEventToTerminalConsole:@"instance disconnected"];
        return;
    }
    
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to start instance!" message:@"Please make sure you already select an instance."];
        return;
    }
    
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    if([[object valueForKey:@"publicIP"] length] == 0)
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to connect instance!" message:@"This instance is currently offline. Please start it first!"];
        return;
    }
    self.ssh = [[DPMasternodeController sharedInstance] connectInstance:object];
    if (!self.ssh.isAuthorized) {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to connect instance!" message:@"SSH: error authenticating with server."];
        return;
    }
    
    //connect instance successfully
    self.connectButton.title = @"Disconnect";
    [self.consoleTabSegmentedControl setSelectedSegment:2];//set console tab to terminal segment.
    terminalHeadString = [NSString stringWithFormat:@"ubuntu@ip-%@:", [object valueForKey:@"publicIP"]];
    NSString *string = [NSString stringWithFormat:@"%@ connected successfully", terminalHeadString];
    [self addStringEventToTerminalConsole:string];
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
    [repoController showRepoWindow:object controller:masternodeController];
    
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
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] setUpMasternodeConfiguration:object onViewCon:masternodeController clb:^(BOOL success, NSString *message) {
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
    if(![object valueForKey:@"rpcPassword"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"You must first have a rpc password for the masternode before you can start it.";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return;
    }
    else {
        [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: trying to start masternode.", [object valueForKey:@"instanceId"]];
        [self addStringEventToMasternodeConsole:eventMsg];
        
        if (![[DPLocalNodeController sharedInstance] dashDPath]) {
            DialogAlert *dialog=[[DialogAlert alloc]init];
            NSAlert *findPathAlert = [dialog getFindPathAlert:@"dashd" exPath:@"~/Documents/src/dash/src"];
            
            if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
                //Find clicked
                NSString *pathString = [dialog getLaunchPath];
                [[DPLocalNodeController sharedInstance] setDashDPath:pathString];
                [[DialogAlert sharedInstance] showAlertWithOkButton:@"dashd" message:@"Set up dashd path successfully."];
            }
        }
        else{
            [[DPMasternodeController sharedInstance] startDashd:object onViewCon:masternodeController clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                if (!success) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    dict[NSLocalizedDescriptionKey] = errorMessage;
                    NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                    [[NSApplication sharedApplication] presentError:error];
                }
            }];
        }
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
    [volumeController showAMIWindow:object];
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
        [self setTerminalCommandState:[NSNumber numberWithInt:0]];
    } else {
        
        if(self.consoleTabSegmentedControl.selectedSegment == 1)
        {
//            NSInteger row = self.tableView.selectedRow;
//            if (row == -1) return;
//            NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//            self.consoleTextView.string = @"Select a running masternode";
            
            [self setTerminalCommandState:[NSNumber numberWithInt:0]];
            
            NSString * consoleEventString = [self.masternodeConsoleEvents printOut];
            self.consoleTextView.string = consoleEventString;
        }
        else if(self.consoleTabSegmentedControl.selectedSegment == 2)
        {
            [self setTerminalCommandState:[NSNumber numberWithInt:1]];
            NSString * consoleEventString = [self.terminalConsoleEvents printOut];
            self.consoleTextView.string = consoleEventString;
        }
    }
}

-(void)setTerminalCommandState:(NSNumber*)state {
    if([state isEqual:@(0)])//hide
    {
        self.commandTextField.hidden = true;
    }
    else {//show
        self.commandTextField.hidden = false;
    }
}

#pragma mark Console tab view delegate

- (IBAction)selectedConsoleTab:(id)sender {
    [self updateConsole];
}

- (IBAction)pressCommandField:(NSTextField*)string {
    
    if(string.stringValue.length == 0) return;
    
    if([self.connectButton.title isEqualToString:@"Connect"])
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to send command!" message:@"Please make sure you connect instance."];
        return;
    }
    
    NSString *terminalString = [NSString stringWithFormat:@"%@ %@", terminalHeadString, string.stringValue];
    [self addStringEventToTerminalConsole:terminalString];
    
    NSError *error;
    NSString *response = [[DPMasternodeController sharedInstance] getResponseExecuteCommand:string.stringValue onSSH:self.ssh error:error];
    if(![response isEqualToString:@""] || [response length] != 0) {
        terminalString = [NSString stringWithFormat:@"%@ %@", terminalHeadString, response];
        [self addStringEventToTerminalConsole:terminalString];
    }
    
    self.commandTextField.stringValue = @"";
}

#pragma mark - Table View

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if(row == -1) {
        //clear all button state
        self.setupButton.enabled = false;
        self.createAmiButton.enabled = false;
        return;
    }
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
//    //Set up button
//    if ([[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Initial) {
//        self.setupButton.enabled = true;
//    }
//    else{
//        self.setupButton.enabled = false;
//    }
    self.setupButton.enabled = true;
    
    //Create AMI button
    if ([[object valueForKey:@"masternodeState"] integerValue] != MasternodeState_Initial) {
        self.createAmiButton.enabled = true;
    }
    else if ([[object valueForKey:@"masternodeState"] integerValue] != MasternodeState_Checking){
        self.createAmiButton.enabled = false;
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
