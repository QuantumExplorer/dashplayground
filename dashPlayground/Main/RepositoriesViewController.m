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
#import "DialogAlert.h"
#import "AvailabilityViewController.h"

@interface RepositoriesViewController ()

@property (strong) IBOutlet NSTableView *tableView;
@property (strong) IBOutlet NSTextField *repositoryAddField;
@property (strong) IBOutlet NSTextField *branchAddField;
@property (strong) IBOutlet NSPopUpButton *repositoryAvailabilityPopUpButton;
@property (strong) IBOutlet NSPopUpButton *repositoryProjectPopUpButton;

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
        
        [[DPDataStore sharedInstance] deleteRepository:object]; //Toey, delete in main context
//        [[DPDataStore sharedInstance] deleteObject:object];
//        [[DPDataStore sharedInstance] saveContext];
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
    
    if([self.startCountField integerValue] <= 100 && [self.startCountField integerValue] >= 1)
    {
//        AvailabilityViewController *availCon = [[AvailabilityViewController alloc] init];
//        NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
//        [availCon showAvailWindow:[self.startCountField integerValue] onBranch:object clb:nil];
        NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
        [[DPMasternodeController sharedInstance] setUpInstances:[self.startCountField integerValue] onBranch:object clb:nil onRegion:nil serverType:@"t2.micro"];
    }
    else
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Warning!" message:@"The number of instances exceeds the limitation (1-100)."];
    }
    
    
}

- (IBAction)pressAddRepository:(id)sender {
    NSString * branchName = [self.branchAddField stringValue];
    if (!branchName || [branchName isEqualToString:@""]) branchName = @"master";
    
    NSUInteger repositoryAvailabilityIndex = [self.repositoryAvailabilityPopUpButton.objectValue integerValue];
    NSUInteger repositoryProjectIndex = [self.repositoryProjectPopUpButton.objectValue integerValue];
    BOOL isPrivate = (repositoryAvailabilityIndex != 0);
    
    if ([[self.repositoryAddField stringValue] length] > 0) {
        NSString * url = [_repositoryAddField stringValue];
        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
        NSArray *matches = [linkDetector matchesInString:url options:0 range:NSMakeRange(0, [url length])];
        NSString * repositoryLocation = nil;
        NSString * user = nil;
        if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
            NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
            if ([url.host isEqualToString:@"github.com"] && ([url.pathExtension isEqualToString:@"git"] || !url.pathExtension) && url.pathComponents.count > 2) {
                repositoryLocation = [url.lastPathComponent stringByDeletingPathExtension];
                user = url.pathComponents[1];
            }
        } else {
            switch (repositoryProjectIndex) {
                case DPRepositoryProject_Core:
                    repositoryLocation = @"dash";
                    break;
                case DPRepositoryProject_Dapi:
                    repositoryLocation = @"dapi";
                    break;
                case DPRepositoryProject_Drive:
                    repositoryLocation = @"dashdrive";
                    break;
                case DPRepositoryProject_Insight:
                    repositoryLocation = @"insight";
                    break;
                case DPRepositoryProject_Sentinel:
                    repositoryLocation = @"sentinel";
                    break;
                    
                default:
                    break;
            }
            
            user = url;
        }
        [[DPRepositoryController sharedInstance] addRepository:repositoryLocation forProject:repositoryProjectIndex forUser:user branchName:branchName isPrivate:isPrivate clb:^(BOOL success, NSString *message) {
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
    if (row == -1) {
        [[DialogAlert sharedInstance] showWarningAlert:@"Refreshing branch" message:@"Please make sure you select a branch."];
        return;
    }
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

- (IBAction)pressSetAmi:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    
    [[DPRepositoryController sharedInstance] setAMIForRepository:object clb:^(BOOL success, NSString *message) {
        
    }];
}


@end
