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
#import "Branch+CoreDataClass.h"
#import "DPRepositoryController.h"

@interface VersioningViewController ()

@property (readonly) NSManagedObjectContext * managedObjectContext;

@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSArrayController *dapiRepositoriesController;
@property (strong) IBOutlet NSArrayController *dapiBranchesController;

@property (strong) IBOutlet NSArrayController *dashDriveRepositoriesController;
@property (strong) IBOutlet NSArrayController *dashDriveBranchesController;

@property (strong) IBOutlet NSArrayController *insightRepositoriesController;
@property (strong) IBOutlet NSArrayController *insightBranchesController;

@property (strong) IBOutlet NSArrayController *sentinelRepositoriesController;
@property (strong) IBOutlet NSArrayController *sentinelBranchesController;

@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextField;

//Core
@property (strong) IBOutlet NSTextField *currentCoreTextField;
@property (strong) IBOutlet NSPopUpButton *coreVersionPopupButton;
@property (strong) IBOutlet NSButton *coreUpdateButton;

@property (strong) IBOutlet NSTextField *currentDapiVersionTextField;
@property (strong) IBOutlet NSComboBox * dapiRepositoriesComboBox;
@property (strong) IBOutlet NSComboBox * dapiBranchesComboBox;
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

@property (strong) IBOutlet NSButton *updateAllButton;
@property (strong) IBOutlet NSTextField * updateProgressTextField;
@property (assign,nonatomic) NSUInteger totalTasks;
@property (assign,nonatomic) NSUInteger completedTasks;

@property (strong,atomic) Masternode* selectedMasternode;

@end

@implementation VersioningViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setUpConsole];
    
    [DPVersioningController sharedInstance].delegate = self;
}

-(NSManagedObjectContext*)managedObjectContext {
    return ((AppDelegate*)[NSApplication sharedApplication].delegate).managedObjectContext;
}

-(void)setCompletedTasks:(NSUInteger)completedTasks {
    [self.updateProgressTextField setStringValue:[NSString stringWithFormat:@"%f %%",100.0*((float)completedTasks)/self.totalTasks]];
    _completedTasks = completedTasks;
}

-(void)finishedTask {
    self.completedTasks++;
}

-(void)versionControllerRelayMessage:(NSString *)message {
    [self addStringEvent:message];
}

-(void)setUpConsole {
    self.consoleEvents = [[ConsoleEventArray alloc] init];
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
    NSArray *dapiHead = [[self.dapiVersionPopUpButton.selectedItem title] componentsSeparatedByString:@","];
    [[DPVersioningController sharedInstance] updateDapi:[self.selectedMasternode valueForKey:@"publicIP"] repositoryUrl:[self.selectedMasternode valueForKey:@"repositoryUrl"] onBranch:@"develop" commitHead:[dapiHead objectAtIndex:0]];
}

- (IBAction)updateDapiToLatest:(id)sender {
    Branch * branch = [self.dapiBranchesController.selectedObjects firstObject];
    [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Dapi toLatestCommitInBranch:branch onMasternode:self.selectedMasternode clb:^(BOOL success, NSError *error) {
        
    }];
}

- (IBAction)updateDashDrive:(id)sender {

}

- (IBAction)updateDashDriveToLatest:(id)sender {
    Branch * branch = [self.dashDriveBranchesController.selectedObjects firstObject];
    [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Drive toLatestCommitInBranch:branch onMasternode:self.selectedMasternode clb:^(BOOL success, NSError *error) {
        
    }];
}

- (IBAction)updateInsight:(id)sender {

}

- (IBAction)updateInsightToLatest:(id)sender {
    Branch * branch = [self.insightBranchesController.selectedObjects firstObject];
    [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Insight toLatestCommitInBranch:branch onMasternode:self.selectedMasternode clb:^(BOOL success, NSError *error) {
        
    }];
}

- (IBAction)updateSentinel:(id)sender {
    
}

- (IBAction)updateSentinelToLatest:(id)sender {
    Branch * branch = [self.sentinelBranchesController.selectedObjects firstObject];
    [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Sentinel toLatestCommitInBranch:branch onMasternode:self.selectedMasternode clb:^(BOOL success, NSError *error) {
        
    }];
}

-(NSDictionary*)allUsedAndDefaultBranchesForRunningMasternodes {
    //first we need to get all the branches required
    NSMutableDictionary * branches = [NSMutableDictionary dictionary];
    Branch * defaultDapiBranch = [[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Dapi];
    Branch * defaultSentinelBranch = [[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Sentinel];
    Branch * defaultDriveBranch = [[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Drive];
    Branch * defaultInsightBranch = [[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Insight];
    branches[@"dapi"] = [NSMutableDictionary dictionaryWithObject:defaultDapiBranch forKey:defaultDapiBranch.name];
    branches[@"drive"] = [NSMutableDictionary dictionaryWithObject:defaultDriveBranch forKey:defaultDriveBranch.name];
    branches[@"insight"] = [NSMutableDictionary dictionaryWithObject:defaultInsightBranch forKey:defaultInsightBranch.name];
    branches[@"sentinel"] = [NSMutableDictionary dictionaryWithObject:defaultSentinelBranch forKey:defaultSentinelBranch.name];
    //to do core
    for (Masternode * masternode in [self.arrayController arrangedObjects]) {
        if (masternode.dapiBranch && ![[branches[@"dapi"] allKeys] containsObject:masternode.dapiBranch.name]) {
            [branches[@"dapi"] setObject:masternode.dapiBranch forKey:masternode.dapiBranch.name];
        }
        if (masternode.driveBranch && ![[branches[@"drive"] allKeys] containsObject:masternode.driveBranch.name]) {
            [branches[@"drive"] setObject:masternode.driveBranch forKey:masternode.driveBranch.name];
        }
        if (masternode.insightBranch && ![[branches[@"insight"] allKeys] containsObject:masternode.insightBranch.name]) {
            [branches[@"insight"] setObject:masternode.insightBranch forKey:masternode.insightBranch.name];
        }
        if (masternode.sentinelBranch && ![[branches[@"sentinel"] allKeys] containsObject:masternode.sentinelBranch.name]) {
            [branches[@"sentinel"] setObject:masternode.sentinelBranch forKey:masternode.sentinelBranch.name];
        }
    }
    return branches;
}


-(NSUInteger)updateMasternodeIfNeeded:(Masternode*)masternode {
    NSUInteger count = 0;
    if (!masternode.dapiBranch) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Dapi toLatestCommitInBranch:[[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Dapi] onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    } else if (![masternode.dapiBranch.lastCommitHash isEqualToString:masternode.dapiGitCommitVersion]) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Dapi toLatestCommitInBranch:masternode.dapiBranch onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    }
    if (!masternode.driveBranch) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Drive toLatestCommitInBranch:[[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Drive] onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    } else if (![masternode.driveBranch.lastCommitHash isEqualToString:masternode.driveGitCommitVersion]) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Drive toLatestCommitInBranch:masternode.driveBranch onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    }
    if (!masternode.insightBranch) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Insight toLatestCommitInBranch:[[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Insight] onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    } else if (![masternode.insightBranch.lastCommitHash isEqualToString:masternode.insightGitCommitVersion]) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Insight toLatestCommitInBranch:masternode.insightBranch onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    }
    if (!masternode.sentinelBranch) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Sentinel toLatestCommitInBranch:[[DPDataStore sharedInstance] defaultBranchForProject:DPRepositoryProject_Sentinel] onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    } else if (![masternode.sentinelBranch.lastCommitHash isEqualToString:masternode.sentinelGitCommitVersion]) {
        [[DPVersioningController sharedInstance] updateProject:DPRepositoryProject_Sentinel toLatestCommitInBranch:masternode.sentinelBranch onMasternode:masternode clb:^(BOOL success, NSError *error) {
            [self finishedTask];
        }];
        count++;
    }
    return count;
}

-(IBAction)updateAll:(id)sender {
    //first we need to get the branches we care about
    __block NSDictionary * tree = [self allUsedAndDefaultBranchesForRunningMasternodes];
    //then we need to make sure they are up to date
    __block NSUInteger updatedBranches = 0;
    for (NSString * projectName in tree) {
        NSDictionary * branches = tree[projectName];
    for (NSString * branchName in branches) {
        Branch * branch = branches[branchName];
        [[DPRepositoryController sharedInstance] updateBranchInfo:branch clb:^(BOOL success, NSString *message) {
            if (!success) return;
            updatedBranches++;
            if (updatedBranches == branches.count) {
                NSUInteger actionCount = 0;
                for (Masternode * masternode in [self.arrayController arrangedObjects]) {
                    actionCount += [self updateMasternodeIfNeeded:masternode];
                }
                self.totalTasks =actionCount;
            }
        }];
    }
    }
}


@end
