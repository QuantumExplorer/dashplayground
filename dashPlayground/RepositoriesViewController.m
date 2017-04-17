//
//  RepositoriesViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "RepositoriesViewController.h"
#import "DPMasternodeController.h"
#import "DPRepositoryController.h"
#import "DPDataStore.h"

@interface RepositoriesViewController ()

@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSTextField *repositoryAddField;
@property (strong) IBOutlet NSTextField *branchAddField;

@end

@implementation RepositoriesViewController

- (BOOL)deleteKeyPressedForTableView:(DPTableView *)tableView {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return FALSE;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    if ([[object valueForKey:@"masternodes"] count]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"This branch has masternodes, stop them first";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    } else {
        [[DPDataStore sharedInstance] deleteObject:object];
        [[DPDataStore sharedInstance] saveContext];
    }
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)pressStartIntances:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Please select a repository and a branch";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return;
    }
    [[DPMasternodeController sharedInstance] runInstances:[self.startCountField integerValue]];
}

- (IBAction)addRepository:(id)sender {
    NSString * branch = [self.branchAddField stringValue];
    if (!branch || [branch isEqualToString:@""]) branch = @"master";
    if ([self.repositoryAddField stringValue]) {
        NSString * url = [_repositoryAddField stringValue];
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
                        self.repositoryAddField.stringValue = @"";
                        self.branchAddField.stringValue = @"";
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
                    self.repositoryAddField.stringValue = @"";
                    self.branchAddField.stringValue = @"";
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

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}



- (IBAction)refreshBranch:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPRepositoryController sharedInstance] updateBranchInfo:object clb:^(BOOL success, NSString *message) {
        if (!success) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = message;
            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
        }
    }];
}
@end
