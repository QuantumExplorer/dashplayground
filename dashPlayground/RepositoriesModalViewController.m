//
//  RepositoriesModalViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 3/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "RepositoriesModalViewController.h"
#import "DPDataStore.h"
#import "NSArray+SWAdditions.h"
#import "RepositoriesViewController.h"
#import "DialogAlert.h"
#import "DPRepositoryController.h"
#import "DPMasternodeController.h"
#import "DPRepoModalController.h"
#import "MasternodeStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"
#import "DPRepoModalController.h"

@interface RepositoriesModalViewController ()

@property (strong) IBOutlet NSArrayController *repositoryArrayCon;
@property (strong) IBOutlet NSTableView *repoTable;

@property (strong) IBOutlet NSTextField *repoNameField;
@property (strong) IBOutlet NSTextField *branchField;

@end

@implementation RepositoriesModalViewController

RepositoriesModalViewController* _repoWindowController;
NSArray * masternodeArrayObjects;
MasternodesViewController *masternodeCon2;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib {
    
    NSLog(@"repository window loaded");
    
    NSMutableArray *repoData = [[DPRepoModalController sharedInstance] getRepositoriesData];
    [self displayData:repoData];
}

-(void)displayData:(NSMutableArray*)repoData {
    if(repoData.count > 0)
    {
        [self.repositoryArrayCon setContent:nil];
        for (NSDictionary* reference in repoData) {
            [self showContentToTable:reference];
        }
    }
    else {
        [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Repository data is empty."];
        [_repoWindowController close];
    }
}

-(void)showContentToTable:(NSDictionary*)dictionary
{
    [self.repositoryArrayCon addObject:dictionary];
    
    [self.repositoryArrayCon rearrangeObjects];
    
    NSArray *array = [self.repositoryArrayCon arrangedObjects];
    NSUInteger row = [array indexOfObjectIdenticalTo:dictionary];
    
    [self.repoTable editColumn:0 row:row withEvent:nil select:YES];
}

-(void)showRepoWindow:(NSArray*)objects controller:(MasternodesViewController*)controller {
    
    if([_repoWindowController.window isVisible]) return;
    
    _repoWindowController = [[RepositoriesModalViewController alloc] initWithWindowNibName:@"RepositoryWindow"];
    [_repoWindowController.window makeKeyAndOrderFront:self];
    masternodeArrayObjects = objects;
    
    masternodeCon2 = controller;
    
    [[DPRepoModalController sharedInstance] setViewController:controller];
}

- (IBAction)pressRefresh:(id)sender {
    NSMutableArray *repoData = [[DPRepoModalController sharedInstance] getRepositoriesData];
    [self displayData:repoData];
}

- (IBAction)pressAddRepository:(id)sender {
    NSString * branch = [self.branchField stringValue];
    if (!branch || [branch isEqualToString:@""]) branch = @"master";
    if (![[self.repoNameField stringValue] isEqualToString:@""]) {
        NSString * url = [self.repoNameField stringValue];
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:url options:0 range:NSMakeRange(0, [url length])];
        if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
            NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
            if ([url.host isEqualToString:@"github.com"] && ([url.pathExtension isEqualToString:@"git"] || !url.pathExtension) && url.pathComponents.count > 2) {
                [[DPRepositoryController sharedInstance] addRepositoryForUser:url.pathComponents[1] repoName:[url.lastPathComponent stringByDeletingPathExtension] branch:branch clb:^(BOOL success, NSString *message) {
                    if (!success) {
                        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                        dict[NSLocalizedDescriptionKey] = message;
                        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                        [[NSApplication sharedApplication] presentError:error];
                    } else {
                        self.repoNameField.stringValue = @"";
                        self.branchField.stringValue = @"";
                        NSMutableArray *repoData = [[DPRepoModalController sharedInstance] getRepositoriesData];
                        [self displayData:repoData];
                        
                        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Add repository" message:@"Repository is added successfully."];
                    }
                }];
            }
        } else {
            [[DPRepositoryController sharedInstance] addRepositoryForUser:url repoName:@"dash" branch:branch clb:^(BOOL success, NSString *message) {
                if (!success) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    dict[NSLocalizedDescriptionKey] = message;
                    NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                    [[NSApplication sharedApplication] presentError:error];
                } else {
                    self.repoNameField.stringValue = @"";
                    self.branchField.stringValue = @"";
                    NSMutableArray *repoData = [[DPRepoModalController sharedInstance] getRepositoriesData];
                    [self displayData:repoData];
                    
                    [[DialogAlert sharedInstance] showAlertWithOkButton:@"Add repository" message:@"Repository is added successfully."];
                }
            }];
        }
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Fields are empty";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction)pressSelect:(id)sender {
    NSInteger row = self.repoTable.selectedRow;
    if (row == -1) {
        [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Please make sure you select a repository."];
        return;
    }
    
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Set up" message:@"Are you sure you want to set up this masternode?"];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        
        [_repoWindowController close];
        
        //Change masternode state
//        masternodeCon2.setupButton.enabled = false;
        
        //reset git username and password
        [DPDataStore sharedInstance].githubUsername = @"";
        [DPDataStore sharedInstance].githubPassword = @"";
        NSManagedObject * repositoryObject = [self.repositoryArrayCon.arrangedObjects objectAtIndex:row];
        
        if([[repositoryObject valueForKey:@"repoType"] integerValue] == 1) {
            if([[[DPDataStore sharedInstance] githubUsername] length] == 0) {
                NSString *githubUsername = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github username" message:@"Please enter your Github username"];
                [DPDataStore sharedInstance].githubUsername = githubUsername;
            }
            if([[[DPDataStore sharedInstance] githubPassword] length] == 0) {
                NSString *githubPassword = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github password" message:@"Please enter your Github password"];
                [DPDataStore sharedInstance].githubPassword = githubPassword;
            }
        }
        
        for(NSManagedObject *masternode in masternodeArrayObjects)
        {
            if([[masternode valueForKey:@"isSelected"] integerValue] != 1) continue;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternode setValue:@(MasternodeState_SettingUp) forKey:@"masternodeState"];
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            });
            
            [masternodeCon2.consoleTabSegmentedControl setSelectedSegment:1];//set console tab to masternode segment.
            
            
            [[DPRepoModalController sharedInstance] setUpMasternodeDashdWithSelectedRepo:masternode repository:repositoryObject clb:^(BOOL success, NSString *message){
                if (!success) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    dict[NSLocalizedDescriptionKey] = message;
                    NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                    [[NSApplication sharedApplication] presentError:error];
                }
            }];
        }
    }
}


@end
