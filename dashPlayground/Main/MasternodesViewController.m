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
#import "SentinelStateTransformer.h"
#import "ChainSelectionViewController.h"

@interface MasternodesViewController ()

@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextView;
@property (strong) IBOutlet NSScrollView *consoleScrollView;
@property (strong) IBOutlet NSButton *selectAllButton;


//Masternode control
@property (strong) IBOutlet NSButtonCell *createAmiButton;
@property (strong) ConsoleEventArray * masternodeConsoleEvents;
@property (strong) IBOutlet NSButton *connectButton;
@property (strong) IBOutlet NSButton *configureButton;
@property (strong) IBOutlet NSButton *startButton;

//Instance control
@property (strong) IBOutlet NSButton *startInstanceButton;

//Terminal
@property (strong) ConsoleEventArray * terminalConsoleEvents;
@property (strong) IBOutlet NSTextField *commandTextField;

@property (strong) NMSSHSession *ssh;

//Table Column
@property (atomic) BOOL chainColumnBool;
@property (atomic) BOOL instanceStateColumnBool;
@property (atomic) BOOL masternodeStateColumnBool;
@property (atomic) BOOL syncStatusColumnBool;
@property (atomic) BOOL gitBranchColumnBool;
@property (atomic) BOOL publicIPColumnBool;
@property (atomic) BOOL gitCommitColumnBool;

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
    [self initilizeTableColumnAttributes];
    masternodeController = self;
    
    DPMasternodeController *masternodeCon = [DPMasternodeController sharedInstance];
    masternodeCon.masternodeViewController = self;
    
    [self.tableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    if ([[[DPDataStore sharedInstance] chainNetwork] rangeOfString:@"devnet"].location != NSNotFound) {
        self.devnetBox.hidden = false;
    }
}

- (void)initilizeTableColumnAttributes {
    _chainColumnBool = NO;
    _instanceStateColumnBool = NO;
    _masternodeStateColumnBool = NO;
    _syncStatusColumnBool = NO;
    _gitBranchColumnBool = NO;
    _publicIPColumnBool = NO;
    _gitCommitColumnBool = NO;
}

- (IBAction)pressCheckDevnet:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    
    NSString *chainName = [[DialogAlert sharedInstance] showAlertWithTextField:@"Checking devnet network" message:@"Please enter your devnet name." placeHolder:@""];
    
    if([chainName length] == 0) {
        [self addStringEventToMasternodeConsole:@"Please make sure you already input your devnet name."];
    }
    
    [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Checking network of devnet name %@.", chainName]];
    
    NSArray * AllMasternodes = [NSArray arrayWithArray:[self.arrayController.arrangedObjects allObjects]];
    [[DPMasternodeController sharedInstance] checkDevnetNetwork:chainName AllMasternodes:AllMasternodes];
}


- (IBAction)pressSetUpDevnet:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Setting up devnet name %@, this would take a while please do not close the application.", [[DPDataStore sharedInstance] chainNetwork]]];
    
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Setting up devnet" message:[NSString stringWithFormat:@"Are you sure you want to create devnet with name %@", [[DPDataStore sharedInstance] chainNetwork]]];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSArray * AllMasternodes = [NSArray arrayWithArray:[self.arrayController.arrangedObjects allObjects]];
        [[DPMasternodeController sharedInstance] setUpDevnet:AllMasternodes];
    }
}


- (IBAction)pressRegisterProtx:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:0];//set console tab to local segment.
    [self addStringEvent:@"Running command protx register on local..."];
    
    NSArray * AllMasternodes = [NSArray arrayWithArray:[self.arrayController.arrangedObjects allObjects]];
    
//    NSArray *AllMasternodes = [self.arrayController.arrangedObjects allObjects];
    
    [[DPMasternodeController sharedInstance] registerProtxForLocal:AllMasternodes];
}


- (IBAction)pressAddNode:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Adding node to local..."];
    
    NSArray *selectedMasternode = [NSArray array];
    NSManagedObject *masternodeObject;
    int countMasternode = 0;
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        if([[object valueForKey:@"isSelected"] integerValue] == 1) {
            selectedMasternode = [selectedMasternode arrayByAddingObject:object];
            countMasternode = countMasternode+1;
            masternodeObject = object;
        }
    }
    
    if(countMasternode > 1) {
        [self addStringEventToMasternodeConsole:@"Main node can be chosen only 1."];
        return;
    }
    
    if(countMasternode == 0) {
        [self addStringEventToMasternodeConsole:@"Please make sure you already select masternode."];
        return;
    }
    
    BOOL isMainNodeSetUp = [[DPMasternodeController sharedInstance] setUpMainNode:masternodeObject];
    if(isMainNodeSetUp == NO) return;
    
    if([selectedMasternode count] != 0) {
        for(NSManagedObject *selectedObject in selectedMasternode)
        {
            for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
            {
                if([[object valueForKey:@"isSelected"] integerValue] != 1 && [object valueForKey:@"publicIP"]) {
                    if(![[selectedObject valueForKey:@"chainNetwork"] isEqualToString:[object valueForKey:@"chainNetwork"]]) continue;
                    
                    [[DPMasternodeController sharedInstance] addNodeToRemote:object toPublicIP:[selectedObject valueForKey:@"publicIP"] clb:^(BOOL success, NSString *message) {
                        if(message == nil) {
                            [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: unable to connect dash core server.", [object valueForKey:@"publicIP"]]];
                        }
                        else if([message length] == 0 || [message length] == 1) {
                            [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: added node %@ successfully.", [object valueForKey:@"publicIP"], [selectedObject valueForKey:@"publicIP"]]];
                        }
                        else {
                            [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: %@", [object valueForKey:@"publicIP"], message]];
                        }
                    }];
                }
            }
        }
        
        for(NSManagedObject *selectedObject in selectedMasternode)
        {
            [[DPMasternodeController sharedInstance] addNodeToLocal:selectedObject clb:^(BOOL success, NSString *message) {
                if([message length] == 0 || [message length] == 1) {
                    [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[LOCAL]: added node %@ successfully.", [selectedObject valueForKey:@"publicIP"]]];
                }
                else {
                    [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[LOCAL]: %@ : %@", [selectedObject valueForKey:@"publicIP"], message]];
                }
            }];
        }
    }
//    [self deSelectAll];
}


- (IBAction)setupSentinel:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Setting up sentinel on remotes..."];
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        if([[object valueForKey:@"isSelected"] integerValue] == 1) {
            [[DPMasternodeController sharedInstance] setUpMasternodeSentinel:object clb:^(BOOL success, NSString *message) {
                [self addStringEventToMasternodeConsole:message];
            }];
            [object setValue:@(0) forKey:@"isSelected"];
        }
    }
}

- (IBAction)checkSentinel:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Checking sentinel on remotes..."];
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        if([[object valueForKey:@"isSelected"] integerValue] == 1) {
            [[DPMasternodeController sharedInstance] checkMasternodeSentinel:object clb:^(BOOL success, NSString *message) {
                if([message length] == 0) {
                    [self addStringEventToMasternodeConsole:@"sentinel is now working."];
                    [object setValue:@(SentinelState_Running) forKey:@"sentinelState"];
                    [[DPDataStore sharedInstance] saveContext];
                }
                else if (success != YES){
                    [object setValue:@(SentinelState_Error) forKey:@"sentinelState"];
                    [[DPDataStore sharedInstance] saveContext];
                    [self addStringEventToMasternodeConsole:message];
                }
                else {
                    [self addStringEventToMasternodeConsole:message];
                }
            }];
        }
    }
}

- (IBAction)configureMasternodeSentinel:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Configuring sentinel on remotes..."];
    
    [[DPMasternodeController sharedInstance] configureMasternodeSentinel:[self.arrayController.arrangedObjects allObjects]];
}


- (IBAction)retreiveInstances:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:0];//set console tab to local segment.
    [self addStringEvent:@"Refreshing instances."];
    [[DPMasternodeController sharedInstance] getInstancesClb:^(BOOL success, NSString *message) {
        [self addStringEvent:@"Refreshed instances."];
        [self deSelectAll];
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


//- (IBAction)getKey:(id)sender {
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1) return;
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//    if (![object valueForKey:@"key"]) {
//        NSString * key = [[[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"masternode genkey" forChain:[object valueForKey:@"chainNetwork"]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        if ([key length] == 51) {
//            [object setValue:key forKey:@"key"];
//        }
//        
//        [[DPDataStore sharedInstance] saveContext];
//    }
//}

- (IBAction)setUp:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Setting up masternode on remotes..."];
    
    NSArray *masternodes = [self.arrayController.arrangedObjects allObjects];
    RepositoriesModalViewController *repoController = [[RepositoriesModalViewController alloc] init];
    [repoController showRepoWindow:masternodes controller:masternodeController];
//    [self deSelectAll];
    
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1) return;
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//    self.setupButton.enabled = false;
//    RepositoriesModalViewController *repoController = [[RepositoriesModalViewController alloc] init];
//    [repoController showRepoWindow:object controller:masternodeController];
}

- (IBAction)configure:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"configuring remotes..."];
    
    NSArray *masternodes = [self.arrayController.arrangedObjects allObjects];
    ChainSelectionViewController *chainView = [[ChainSelectionViewController alloc] init];
    [chainView showChainSelectionWindow:masternodes];
//    [self deSelectAll];
    
    
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1) return;
//    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//
//    ChainSelectionViewController *chainView = [[ChainSelectionViewController alloc] init];
//    [chainView showChainSelectionWindow:object];
}

- (IBAction)pressSelectAll:(id)sender {
    NSNumber *stateValue;
    if(self.selectAllButton.state == 1){
        stateValue = @(1);
    }
    else{
        stateValue = @(0);
    }
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        if(![object valueForKey:@"publicIP"] || [[object valueForKey:@"instanceState"] integerValue] == InstanceState_Stopped
           || [[object valueForKey:@"instanceState"] integerValue] == InstanceState_Pending
           || [[object valueForKey:@"instanceState"] integerValue] == InstanceState_Terminated) continue;
        [object setValue:stateValue forKey:@"isSelected"];
    }
}

-(void)deSelectAll {
    self.selectAllButton.state = 0;
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        [object setValue:@(0) forKey:@"isSelected"];
    }
}

- (IBAction)pressStartDashd:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Starting dashd server on remotes..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
        {
            if([[object valueForKey:@"isSelected"] integerValue] == 1) {
                [[DPMasternodeController sharedInstance] startDashdOnRemote:object onClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addStringEventToMasternodeConsole:message];
                    });
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
//                    [object setValue:@(0) forKey:@"isSelected"];
                    [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
                });
            }
        }
    });
}


- (IBAction)stopRemote:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Stopping dashd on remotes..."];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
        {
            if([[object valueForKey:@"isSelected"] integerValue] == 1) {
                [[DPMasternodeController sharedInstance] stopDashdOnRemote:object onClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self addStringEventToMasternodeConsole:message];
                    });
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [object setValue:@(MasternodeState_Stopped) forKey:@"masternodeState"];
                    [object setValue:@(0) forKey:@"isSelected"];
                    [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
                });
            }
        }
    });
//    [self deSelectAll];
}

- (IBAction)wipeRemote:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Wiping all dash data on remotes..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
        {
            if([[object valueForKey:@"isSelected"] integerValue] == 1) {
//                [[DPMasternodeController sharedInstance] stopDashdOnRemote:object onClb:^(BOOL success, NSString *message) {
                    [[DPMasternodeController sharedInstance] wipeDataOnRemote:object onClb:^(BOOL success, NSString *message) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self addStringEventToMasternodeConsole:message];
                        });
                    }];
//                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [object setValue:nil forKey:@"lastBlock"];
                    [object setValue:@(0) forKey:@"isSelected"];
                    [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
                });
            }
        }
    });
    //    [self deSelectAll];
}

//[self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
//[self addStringEventToMasternodeConsole:@"Stopping dashd on remotes..."];
//
//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
//    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
//    {
//        if([[object valueForKey:@"isSelected"] integerValue] == 1) {
//        }
//    }
//});

- (IBAction)startRemote:(id)sender {
    
    [self addStringEventToMasternodeConsole:@"starting masternode on remotes..."];
    
    [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    
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
        
        __block NSString *eventMsg = @"";
        __block NSString *localChain = [[DPDataStore sharedInstance] chainNetwork];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
            {
                if([[object valueForKey:@"isSelected"] integerValue] == 1) {
                    if (![object valueForKey:@"key"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: This remote must first have a key for the masternode before you can start it.", [object valueForKey:@"instanceId"]];
                            [self addStringEventToMasternodeConsole:eventMsg];
//                            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//                            dict[NSLocalizedDescriptionKey] = @"You must first have a key for the masternode before you can start it.";
//                            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
//                            [[NSApplication sharedApplication] presentError:error];
                            return;
                        });
                    }
                    if (![object valueForKey:@"instanceId"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: This remote is not available.", [object valueForKey:@"instanceId"]];
                            [self addStringEventToMasternodeConsole:eventMsg];
//                            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//                            dict[NSLocalizedDescriptionKey] = @"You must first have a key for the masternode before you can start it.";
//                            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
//                            [[NSApplication sharedApplication] presentError:error];
                            return;
                        });
                    }
                    if(![object valueForKey:@"rpcPassword"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: This remote must first have a rpc password for the masternode before you can start it.", [object valueForKey:@"instanceId"]];
                            [self addStringEventToMasternodeConsole:eventMsg];
//                            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
//                            dict[NSLocalizedDescriptionKey] = @"You must first have a rpc password for the masternode before you can start it.";
//                            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
//                            [[NSApplication sharedApplication] presentError:error];
                            return;
                        });
                    }
                    else {
                        [[DPLocalNodeController sharedInstance] checkDash:^(BOOL active) {
                            if (active) {
                                eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: trying to start masternode.", [object valueForKey:@"instanceId"]];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self addStringEventToMasternodeConsole:eventMsg];
                                });
                                [[DPMasternodeController sharedInstance] startMasternodeOnRemote:object localChain:localChain clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [self addStringEventToMasternodeConsole:errorMessage];
                                    });
                                }];
                            }
                            else {
                                [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
                                    if (success) {
                                        eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: trying to start masternode.", [object valueForKey:@"instanceId"]];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self addStringEventToMasternodeConsole:eventMsg];
                                        });
                                        [[DPMasternodeController sharedInstance] startMasternodeOnRemote:object localChain:localChain clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self addStringEventToMasternodeConsole:errorMessage];
                                            });
                                        }];
                                    }
                                    else {
                                        eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Unable to connect dashd server.", [object valueForKey:@"instanceId"]];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [self addStringEventToMasternodeConsole:eventMsg];
                                        });
                                    }
                                } forChain:[object valueForKey:@"chainNetwork"]];
                            }
                        } forChain:[object valueForKey:@"chainNetwork"]];
                    }
                }
            }
        });
    }
}

- (IBAction)startInstance:(id)sender {
    [self.consoleTabSegmentedControl setSelectedSegment:0];//set console tab to local segment.
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        if([[object valueForKey:@"isSelected"] integerValue] == 1 ) {
            [self addStringEvent:FS(@"Starting instance %@",[object valueForKey:@"instanceId"])];
            [[DPMasternodeController sharedInstance] startInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
                [self addStringEvent:FS(@"Instance in boot up process : %@",[object valueForKey:@"instanceId"])];
            }];
        }
    }
//    [self deSelectAll];
    
            
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1)
//    {
//        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to start instance!" message:@"Please make sure you already select an instance."];
//        return;
//    }
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//    [self addStringEvent:FS(@"Starting instance %@",[object valueForKey:@"instanceId"])];
//    [[DPMasternodeController sharedInstance] startInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
//        [self addStringEvent:FS(@"Instance in boot up process : %@",[object valueForKey:@"instanceId"])];
//    }];
}


- (IBAction)stopInstance:(id)sender {
    NSString *msgAlert = FS(@"Are you sure you want to stop instances?");
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Stop instance" message:msgAlert];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self.consoleTabSegmentedControl setSelectedSegment:0];//set console tab to local segment.
        
        for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
        {
            if([[object valueForKey:@"isSelected"] integerValue] == 1) {
                [self addStringEvent:FS(@"Trying to stop instance %@",[object valueForKey:@"instanceId"])];
                [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
                    [self addStringEvent:FS(@"Stopping instance %@",[object valueForKey:@"instanceId"])];
                }];
            }
        }
    }
//    [self deSelectAll];
    
    
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1)
//    {
//        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to stop instance!" message:@"Please make sure you already select an instance."];
//        return;
//    }
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//
//    NSString *msgAlert = FS(@"Are you sure you want to stop instance id %@?", [object valueForKey:@"instanceId"]);
//
//    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Stop instance" message:msgAlert];
//
//    if ([alert runModal] == NSAlertFirstButtonReturn) {
//        [self addStringEvent:FS(@"Trying to stop instance %@",[object valueForKey:@"instanceId"])];
//        [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
//            [self addStringEvent:FS(@"Stopping instance %@",[object valueForKey:@"instanceId"])];
//        }];
//    }
}

- (IBAction)terminateInstance:(id)sender {
    
    NSString *msgAlert = FS(@"Are you sure you want to terminate instances?");
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Terminate instance" message:msgAlert];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self.consoleTabSegmentedControl setSelectedSegment:0];//set console tab to local segment.
        
        for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
        {
            if([[object valueForKey:@"isSelected"] integerValue] == 1) {
                [self addStringEvent:FS(@"Trying to terminate %@",[object valueForKey:@"instanceId"])];
                [[DPMasternodeController sharedInstance] terminateInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
                    [self addStringEvent:FS(@"Terminating instance %@",[object valueForKey:@"instanceId"])];
                }];
            }
        }
    }
        
                
                
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1)
//    {
//        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to terminate instance!" message:@"Please make sure you already select an instance."];
//        return;
//    }
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//
//    NSString *msgAlert = FS(@"Are you sure you want to terminate instance id %@?", [object valueForKey:@"instanceId"]);
//
//    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Terminate instance" message:msgAlert];
//
//    if ([alert runModal] == NSAlertFirstButtonReturn) {
//        [self addStringEvent:FS(@"Trying to terminate %@",[object valueForKey:@"instanceId"])];
//        [[DPMasternodeController sharedInstance] terminateInstance:[object valueForKey:@"instanceId"] clb:^(BOOL success,InstanceState state, NSString *message) {
//            [self addStringEvent:FS(@"Terminating instance %@",[object valueForKey:@"instanceId"])];
//        }];
//    }
    
}

- (IBAction)createNewInstance:(id)sender {
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Create new instance" message:@"Are you sure you want to create a new instance with initial AMI?"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [self addStringEvent:FS(@"Trying to create a new instance.")];
        
        [[DPMasternodeController sharedInstance] createInstanceWithInitialAMI:^(BOOL success, InstanceState state, NSString *message) {
            if(success)
            {
                [self addStringEvent:FS(@"new instance is created succesfully.")];
            }
            else{
                [self addStringEvent:FS(@"creating new instance failure.")];
            }
        } serverType:@"t2.micro"];
    }
    
}

- (IBAction)createAMI:(id)sender {
//    NSInteger row = self.tableView.selectedRow;
//    if (row == -1)
//    {
//        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create new AMI!" message:@"Please make sure you already select an instance."];
//        return;
//    }
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
    int countSelected = 0;
    NSManagedObject *selectedInstance = nil;
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        if([[object valueForKey:@"isSelected"] integerValue] == 1) {
            selectedInstance = object;
            countSelected = countSelected+1;
            
//            [object setValue:nil forKey:@"transactionId"];
//                [object setValue:nil forKey:@"transactionOutputIndex"];
//            [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
            //    dispatch_async(dispatch_get_main_queue(), ^{
            //        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            //
            //    });
        }
    }
    
    if (countSelected > 1)
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create new AMI!" message:@"Please select only 1 instance to create AMI."];
        return;
    }
    
    if(selectedInstance == nil) {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create new AMI!" message:@"Please make sure you already select an instance."];
        return;
    }
    VolumeViewController *volumeController = [[VolumeViewController alloc]init];
    [volumeController showAMIWindow:selectedInstance];
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if([string length] == 0 || string == nil) return;
        ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
        [self.masternodeConsoleEvents addConsoleEvent:consoleEvent];
        [self updateConsole];
    });
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
    [self.consoleScrollView scrollRectToVisible:CGRectMake(self.consoleScrollView.contentSize.width - 1, self.consoleScrollView.contentSize.height -1 , 1, 1) ];
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
    else if(error){
        terminalString = [NSString stringWithFormat:@"%@ %@", terminalHeadString, [error localizedDescription]];
        [self addStringEventToTerminalConsole:terminalString];
    }
    
    self.commandTextField.stringValue = @"";
}

#pragma mark - Table View

- (void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)tableColumn {
    if([[tableColumn title] isEqualToString:@"IP Address"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"publicIP" ascending:_publicIPColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_publicIPColumnBool == YES) _publicIPColumnBool = NO;
        else _publicIPColumnBool = YES;
    }
    else if([[tableColumn title] isEqualToString:@"Chain"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"chainNetwork" ascending:_chainColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_chainColumnBool == YES) _chainColumnBool = NO;
        else _chainColumnBool = YES;
    }
    else if([[tableColumn title] isEqualToString:@"Instance State"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"instanceState" ascending:_instanceStateColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_instanceStateColumnBool == YES) _instanceStateColumnBool = NO;
        else _instanceStateColumnBool = YES;
    }
    else if([[tableColumn title] isEqualToString:@"Masternode State"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"masternodeState" ascending:_masternodeStateColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_masternodeStateColumnBool == YES) _masternodeStateColumnBool = NO;
        else _masternodeStateColumnBool = YES;
    }
    else if([[tableColumn title] isEqualToString:@"Sync State"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"syncStatus" ascending:_syncStatusColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_syncStatusColumnBool == YES) _syncStatusColumnBool = NO;
        else _syncStatusColumnBool = YES;
    }
    else if([[tableColumn title] isEqualToString:@"Branch"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"gitBranch" ascending:_gitBranchColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_gitBranchColumnBool == YES) _gitBranchColumnBool = NO;
        else _gitBranchColumnBool = YES;
    }
    else if([[tableColumn title] isEqualToString:@"Git Head"]) {
        NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey: @"gitCommit" ascending:_gitCommitColumnBool];
        [self.arrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        if(_gitCommitColumnBool == YES) _gitCommitColumnBool = NO;
        else _gitCommitColumnBool = YES;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
//    NSInteger row = self.tableView.selectedRow;
//    if(row == -1) {
//        //clear all button state
//        self.setupButton.enabled = false;
//        self.createAmiButton.enabled = false;
//        return;
//    }
//    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//    
//    //Set up button
////    if ([[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Installed
////        || [[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Running
////        || [[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_SettingUp) {
////        self.setupButton.enabled = false;
////    }
////    else{
////        self.setupButton.enabled = true;
////    }
//    self.setupButton.enabled = true;
//    
//    //Create AMI button
//    //Start button
//    if ([[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Running
//        || [[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Configured
//        || [[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Installed) {
//        self.startButton.enabled = true;
//        self.createAmiButton.enabled = true;
//    }
//    else{
//        self.startButton.enabled = false;
//        self.createAmiButton.enabled = false;
//    }
}

#pragma mark - Block Control

- (IBAction)pressInvalidateButton:(id)sender {
    
    NSString *blockhash = [[DialogAlert sharedInstance] showAlertWithTextField:@"Validating Block" message:@"Please input block hash that you want to validate." placeHolder:@"hash"];
    
    if([blockhash length] > 0) {
        [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
        [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Invalidating block hash %@", blockhash]];
        
        NSArray *masternodeObjects = [self.arrayController.arrangedObjects allObjects];
        
        [[DPMasternodeController sharedInstance] validateMasternodeBlock:masternodeObjects blockHash:blockhash clb:^(BOOL success, NSString *message) {
            if(success == YES) {
                [self addStringEventToMasternodeConsole:message];
            }
        }];
    }
}

- (IBAction)pressReconsiderButton:(id)sender {
    
    NSString *blockhash = [[DialogAlert sharedInstance] showAlertWithTextField:@"Reconsidering Block" message:@"Please input block hash that you want to reconsider." placeHolder:@"hash"];
    
    if([blockhash length] > 0) {
        [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
        [self addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Reconsidering block hash %@", blockhash]];
        
        NSArray *masternodeObjects = [self.arrayController.arrangedObjects allObjects];
        
        [[DPMasternodeController sharedInstance] reconsiderMasternodeBlock:masternodeObjects blockHash:blockhash clb:^(BOOL success, NSString *message) {
            if(success == YES) {
                [self addStringEventToMasternodeConsole:message];
            }
        }];
    }
}

- (IBAction)pressClearBannedButton:(id)sender {
    

        [self.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
    [self addStringEventToMasternodeConsole:@"Clear Banned for Nodes:"];
        
        NSArray *masternodeObjects = [self.arrayController.arrangedObjects allObjects];
        
        [[DPMasternodeController sharedInstance] clearBannedOnNodes:masternodeObjects withCallback:^(BOOL success, NSString *message) {
            if(success == YES) {
                [self addStringEventToMasternodeConsole:message];
            }
        }];
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
