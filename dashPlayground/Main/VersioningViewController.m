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
#import "MasternodeStateTransformer.h"

@interface VersioningViewController ()

@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;

@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextField;

//Core
@property (strong) IBOutlet NSTextField *currentCoreTextField;
@property (strong) IBOutlet NSPopUpButton *versionCoreButton;
@property (strong) IBOutlet NSButton *coreUpdateButton;

//Sentinel
@property (strong) IBOutlet NSTextField *currentSentinelTextField;
@property (strong) IBOutlet NSComboBox *versionSentinelButton;
@property (strong) IBOutlet NSButton *sentinelUpdateButton;

@end

@implementation VersioningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setUpConsole];
    [self initializeTable];
}

-(void)setUpConsole {
    self.consoleEvents = [[ConsoleEventArray alloc] init];
}

- (void)initializeTable {
//    [self addStringEvent:@"Initializing instances from AWS."];
    NSArray * masternodesArray = [[DPDataStore sharedInstance] allMasternodes];
    for (NSManagedObject * masternode in masternodesArray) {
        [self showTableContent:masternode];
//        [[DPMasternodeController sharedInstance] checkMasternode:masternode];
    }
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
        [self.versionCoreButton removeAllItems];
        
        self.sentinelUpdateButton.enabled = false;
        self.currentSentinelTextField.stringValue = @"";
        return;
    }
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
    //Show current git head
    if([[object valueForKey:@"gitCommit"] length] > 0) {
        self.currentCoreTextField.stringValue = [object valueForKey:@"gitCommit"];
        self.coreUpdateButton.enabled = true;
    }
    else {
        self.coreUpdateButton.enabled = false;
        self.currentCoreTextField.stringValue = @"";
    }
    
    if([[object valueForKey:@"sentinelGitCommit"] length] > 0) {
        self.currentSentinelTextField.stringValue = [object valueForKey:@"sentinelGitCommit"];
        self.sentinelUpdateButton.enabled = true;
    }
    else {
        self.sentinelUpdateButton.enabled = false;
        self.currentSentinelTextField.stringValue = @"";
    }
    
    //Show repositories version
    if ([[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Installed
        || [[object valueForKey:@"masternodeState"] integerValue] == MasternodeState_Running) {
        NSMutableArray *commitArrayData = [[DPVersioningController sharedInstance] getGitCommitInfo:object repositoryUrl:[object valueForKey:@"repositoryUrl"] onBranch:[object valueForKey:@"gitBranch"]];
        [self.versionCoreButton removeAllItems];
        [self.versionCoreButton addItemsWithTitles:commitArrayData];
    }
    
}

- (IBAction)refresh:(id)sender {
    [self addStringEvent:@"Refreshing instance(s)."];
    NSArray * masternodesArray = [[DPDataStore sharedInstance] allMasternodes];
    for (NSManagedObject * masternode in masternodesArray) {
//        [self showTableContent:masternode];
        [[DPMasternodeController sharedInstance] checkMasternode:masternode];
    }
}

@end
