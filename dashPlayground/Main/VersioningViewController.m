//
//  VersioningViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 27/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "VersioningViewController.h"
#import "DPMasternodeController.h"
#import "DPDataStore.h"
#import "ConsoleEventArray.h"
#import <AFNetworking/AFNetworking.h>
#import "DPLocalNodeController.h"
#import "DPVersioningController.h"
#import "DashcoreStateTransformer.h"
#import "DialogAlert.h"
#import "Masternode+CoreDataClass.h"
#import "AppDelegate.h"

@interface VersioningViewController ()

@property (readonly) NSManagedObjectContext * managedObjectContext;

@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSArrayController *dapiRepositoriesController;

@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextField;

//Core
@property (strong) IBOutlet NSTextField *currentCoreTextField;
@property (strong) IBOutlet NSPopUpButton *coreVersionPopupButton;
@property (strong) IBOutlet NSButton *coreUpdateButton;

@property (strong) IBOutlet NSTextField *currentDapiVersionTextField;
@property (strong) IBOutlet NSPopUpButton *dapiVersionPopUpButton;
@property (strong) IBOutlet NSButton *dapiUpdateButton;
@property (strong) IBOutlet NSButton *dapiUpdateToLatestButton;

@property (strong) IBOutlet NSTextField *currentDashDriveVersionTextField;
@property (strong) IBOutlet NSPopUpButton *dashDriveVersionPopUpButton;
@property (strong) IBOutlet NSButton *dashDriveUpdateButton;
@property (strong) IBOutlet NSButton *dashDriveUpdateToLatestButton;

@property (strong) IBOutlet NSTextField *currentInsightVersionTextField;
@property (strong) IBOutlet NSButton *insightUpdateButton;
@property (strong) IBOutlet NSButton *insightUpdateToLatestButton;

//Sentinel
@property (strong) IBOutlet NSTextField *currentSentinelTextField;
@property (strong) IBOutlet NSComboBox *versionSentinelButton;

@property (strong) IBOutlet NSButton *sentinelUpdateButton;
@property (strong) IBOutlet NSButton *sentinelUpdateToLatestButton;

@property (strong,atomic) Masternode* selectedMasternode;

@end

@implementation VersioningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setUpConsole];
    [self initialize];
    
    [DPVersioningController sharedInstance].delegate = self;
}

-(NSManagedObjectContext*)managedObjectContext {
    return ((AppDelegate*)[NSApplication sharedApplication].delegate).managedObjectContext;
}

-(void)versionControllerRelayMessage:(NSString *)message {
    [self addStringEvent:message];
}

-(void)setUpConsole {
    self.consoleEvents = [[ConsoleEventArray alloc] init];
}

- (void)initialize {
    //    [self addStringEvent:@"Initializing instances from AWS."];
    NSArray * masternodesArray = [[DPDataStore sharedInstance] allMasternodesWithPredicate:[NSPredicate predicateWithFormat:@"instanceState == %@",@(InstanceState_Running)]];
    for (NSManagedObject * masternode in masternodesArray) {
        [self showTableContent:masternode];
        //        [[DPMasternodeController sharedInstance] checkMasternode:masternode];
    }
    
    [self.coreVersionPopupButton removeAllItems];
    [self.versionSentinelButton removeAllItems];
}

-(void)showTableContent:(NSManagedObject*)object
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.arrayController addObject:object];
        [self.arrayController rearrangeObjects];
    });
}

-(void)addStringEvent:(NSString*)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([string length] == 0 || string == nil) return;
        ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
        [self.consoleEvents addConsoleEvent:consoleEvent];
        [self updateConsole];
    });
}

-(void)updateConsole {
    NSString * consoleEventString = [self.consoleEvents printOut];
    self.consoleTextField.string = consoleEventString;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.tableView.selectedRow;
    if(row == -1) {
        self.coreUpdateButton.enabled = false;
        self.currentCoreTextField.stringValue = @"";
        [self.coreVersionPopupButton removeAllItems];
        
        self.sentinelUpdateButton.enabled = false;
        self.currentSentinelTextField.stringValue = @"";
        return;
    }
    Masternode * masternode = [self.arrayController.arrangedObjects objectAtIndex:row];
    [self addStringEvent:@"Fetching information."];
    self.selectedMasternode = masternode;
    
    //Show current git head
    if([masternode.coreGitCommitVersion length] > 0) {
        self.currentCoreTextField.stringValue = masternode.coreGitCommitVersion;
        self.coreUpdateButton.enabled = true;
    }
    else {
        self.coreUpdateButton.enabled = false;
        self.currentCoreTextField.stringValue = @"";
    }
    
    if([masternode.sentinelGitCommitVersion length] > 0) {
        self.currentSentinelTextField.stringValue = masternode.sentinelGitCommitVersion;
        self.sentinelUpdateButton.enabled = true;
    }
    else {
        self.sentinelUpdateButton.enabled = false;
        self.currentSentinelTextField.stringValue = @"";
    }
    
    //Show repositories version
    if (masternode.dashcoreState != DashcoreState_Initial || masternode.dashcoreState != DashcoreState_SettingUp) {
        [[DPVersioningController sharedInstance] fetchGitCommitInfoOnMasternode:masternode forProject:DPRepositoryProject_Core clb:^(BOOL success, NSArray *commitArrayData) {
            if (success) {
                [self.coreVersionPopupButton removeAllItems];
                if(commitArrayData != nil) [self.coreVersionPopupButton addItemsWithTitles:commitArrayData];
            }
        }];
    }
    
    
    //Show dapi version
    if (masternode.dashcoreState != DashcoreState_Initial || masternode.dashcoreState != DashcoreState_SettingUp) {
        [[DPVersioningController sharedInstance] fetchGitCommitInfoOnMasternode:masternode forProject:DPRepositoryProject_Dapi clb:^(BOOL success, NSArray *commitArrayData) {
            if (success) {
                [self.dapiVersionPopUpButton removeAllItems];
                if(commitArrayData != nil) [self.dapiVersionPopUpButton addItemsWithTitles:commitArrayData];
            }
        }];
    }
    [self addStringEvent:@"Fetched information."];
}

- (IBAction)refresh:(id)sender {
    [self addStringEvent:@"Refreshing instance(s)."];
    NSArray * masternodesArray = [[DPDataStore sharedInstance] allMasternodes];
    for (NSManagedObject * masternode in masternodesArray) {
        //        [self showTableContent:masternode];
        [[DPMasternodeController sharedInstance] checkMasternode:masternode];
    }
}

- (IBAction)updateCoreButton:(id)sender {
    NSArray *coreHead = [[self.coreVersionPopupButton.selectedItem title] componentsSeparatedByString:@","];
    
    if([coreHead count] == 3)
    {
        NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Warning!" message:@"Are you sure you already stopped dashd server before updating new version?"];
        
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            [[DPVersioningController sharedInstance] updateCore:[self.selectedMasternode valueForKey:@"publicIP"] repositoryUrl:[self.selectedMasternode valueForKey:@"repositoryUrl"] onBranch:[self.selectedMasternode valueForKey:@"gitBranch"] commitHead:[coreHead objectAtIndex:0]];
        }
    }
    
    
}

- (IBAction)updateDapi:(id)sender {
    
}

- (IBAction)updateDapiToLatest:(id)sender {
    NSArray *dapiHead = [[self.dapiVersionPopUpButton.selectedItem title] componentsSeparatedByString:@","];
    [[DPVersioningController sharedInstance] updateDapi:[self.selectedMasternode valueForKey:@"publicIP"] repositoryUrl:[self.selectedMasternode valueForKey:@"repositoryUrl"] onBranch:@"develop" commitHead:[dapiHead objectAtIndex:0]];
}

- (IBAction)updateDashDrive:(id)sender {
    
}

- (IBAction)updateDashDriveToLatest:(id)sender {
    
}

- (IBAction)updateInsight:(id)sender {
    
}

- (IBAction)updateInsightToLatest:(id)sender {
    
}

- (IBAction)updateSentinel:(id)sender {
    
}

- (IBAction)updateSentinelToLatest:(id)sender {
    
}


@end
