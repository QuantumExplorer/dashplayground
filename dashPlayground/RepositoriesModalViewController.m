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

@interface RepositoriesModalViewController ()

@property (strong) IBOutlet NSArrayController *repositoryArrayCon;
@property (strong) IBOutlet NSTableView *repoTable;

@property (strong) IBOutlet NSTextField *repoNameField;
@property (strong) IBOutlet NSTextField *branchField;

@end

@implementation RepositoriesModalViewController

RepositoriesModalViewController* _repoWindowController;
NSManagedObject * masternodeObject;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)awakeFromNib {
    
    NSLog(@"repository window loaded");
    
    NSMutableArray *repoData = [self getRepositoriesData];
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

-(NSMutableArray*)getRepositoriesData {
    NSArray *repoData = [[DPDataStore sharedInstance] allRepositories];
    NSMutableArray * repositoryArray = [NSMutableArray array];
    
    NSUInteger count = [repoData count];
    for (NSUInteger i = 0; i < count; i++) {
        //repository entity
        NSManagedObject *repository = (NSManagedObject *)[repoData objectAtIndex:i];
        //branch entity
        NSManagedObject *branch = (NSManagedObject *)[repository valueForKey:@"branches"];
        
        NSDictionary * rDict = [NSMutableDictionary dictionary];
        
        [rDict setValue:[repository valueForKey:@"url"] forKey:@"repository.url"];
        [rDict setValue:[[branch valueForKey:@"name"] anyObject] forKey:@"branchName"];
        
        [repositoryArray addObject:rDict];
    }

    
    return repositoryArray;
}

-(void)showContentToTable:(NSDictionary*)dictionary
{
    [self.repositoryArrayCon addObject:dictionary];
    
    [self.repositoryArrayCon rearrangeObjects];
    
    NSArray *array = [self.repositoryArrayCon arrangedObjects];
    NSUInteger row = [array indexOfObjectIdenticalTo:dictionary];
    
    [self.repoTable editColumn:0 row:row withEvent:nil select:YES];
}

-(void)showRepoWindow:(NSManagedObject*)object {
    
    _repoWindowController = [[RepositoriesModalViewController alloc] initWithWindowNibName:@"RepositoryWindow"];
    [_repoWindowController.window makeKeyAndOrderFront:self];
    masternodeObject = object;
}

- (IBAction)pressRefresh:(id)sender {
    NSMutableArray *repoData = [self getRepositoriesData];
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
                        NSMutableArray *repoData = [self getRepositoriesData];
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
                    NSMutableArray *repoData = [self getRepositoriesData];
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
        
        NSManagedObject * object = [self.repositoryArrayCon.arrangedObjects objectAtIndex:row];
        
        [[DPMasternodeController sharedInstance] setUpMasternodeDashdWithSelectedRepo:masternodeObject repository:object clb:^(BOOL success, NSString *message) {
            if (!success) {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict[NSLocalizedDescriptionKey] = message;
                NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                [[NSApplication sharedApplication] presentError:error];
            }
        }];
    }
}


@end
