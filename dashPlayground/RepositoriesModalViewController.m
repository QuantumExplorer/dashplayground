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
#import "DashcoreStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"
#import "DPRepoModalController.h"
#import "Masternode+CoreDataClass.h"

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
    NSLog(@"repository window loaded");
    
    NSMutableArray *repoData = [[DPRepoModalController sharedInstance] getRepositoriesData];
    [self displayData:repoData];
}

//- (void)awakeFromNib {
//
//    NSLog(@"repository window loaded");
//
//    NSMutableArray *repoData = [[DPRepoModalController sharedInstance] getRepositoriesData];
//    [self displayData:repoData];
//}

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
        [_repoWindowController.window close];
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
    NSString * branchName = [self.branchField stringValue];
    if (!branchName || [branchName isEqualToString:@""]) branchName = @"master";
    if (![[self.repoNameField stringValue] isEqualToString:@""]) {
        NSString * url = [self.repoNameField stringValue];
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:url options:0 range:NSMakeRange(0, [url length])];
        NSString * user = nil;
        NSString * repositoryLocation = nil;
        if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
            NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
            if ([url.host isEqualToString:@"github.com"] && ([url.pathExtension isEqualToString:@"git"] || !url.pathExtension) && url.pathComponents.count > 2) {
                user = url.pathComponents[1];
                repositoryLocation = [url.lastPathComponent stringByDeletingPathExtension];
            } else {
                return;
            }
        } else {
            user = url;
            repositoryLocation = @"dash";
        }
        [[DPRepositoryController sharedInstance] addRepository:repositoryLocation forProject:0 forUser:user branchName:branchName isPrivate:NO clb:^(BOOL success, NSString *message) {
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
        

        Repository * repositoryObject = [self.repositoryArrayCon.arrangedObjects objectAtIndex:row];
        
        if(repositoryObject.isPrivate) {
//maybe do some auth here
        }
        
        for(Masternode *masternode in masternodeArrayObjects)
        {
            if(!masternode.isSelected) continue;
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.dashcoreState = DPDashcoreState_SettingUp;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            
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
