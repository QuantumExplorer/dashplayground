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

@interface MasternodesViewController ()
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;

@end

@implementation MasternodesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)retreiveInstances:(id)sender {
    [[DPMasternodeController sharedInstance] getInstances];
    
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
    [[DPMasternodeController sharedInstance] setUpMasternodeDashd:object];
}

-(void)configureStep2:(NSManagedObject*)object {
    [[DPLocalNodeController sharedInstance] stopDash:^(BOOL success, NSString *message) {
        if (success) {
            NSString *fullpath = @"/Users/samuelw/Library/Application Support/Dashcore/testnet3/masternode.conf";
            NSError * error = nil;
            NSString *contents = [NSString stringWithContentsOfFile:fullpath encoding:NSUTF8StringEncoding error:&error];
            NSMutableArray * lines = [[contents componentsSeparatedByString:@"\n"] mutableCopy];
            NSMutableArray * specialLines = [NSMutableArray array];
            for (int i = ((int)[lines count]) - 1;i> -1;i--) {
                if ([lines[i] hasPrefix:@"#"]) {
                    [specialLines addObject:[lines objectAtIndex:i]];
                    [lines removeObjectAtIndex:i];
                } else
                    if ([lines[i] isEqualToString:@""]) {
                        [lines removeObjectAtIndex:i];
                    } else
                        if ([lines[i] hasPrefix:[object valueForKey:@"instanceId"]]) {
                            [lines removeObjectAtIndex:i];
                        }
            }
            [lines addObject:[NSString stringWithFormat:@"%@ %@:19999 %@ %@ %@",[object valueForKey:@"instanceId"],[object valueForKey:@"publicIP"],[object valueForKey:@"key"],[object valueForKey:@"transactionId"],[object valueForKey:@"transactionOutputIndex"]]];
            NSString * content = [[[specialLines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"] stringByAppendingString:[lines componentsJoinedByString:@"\n"]];
            [content writeToFile:fullpath
                      atomically:NO
                        encoding:NSStringEncodingConversionAllowLossy
                           error:nil];
            if (error) {
                NSLog(@"error");
            } else {
                [[DPMasternodeController sharedInstance] configureMasternode:object];
            }
        } else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = @"Error stoping dash server to place configuration file.";
            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
            return;
        }
    }];
}

- (IBAction)configure:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    __block NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    if (![object valueForKey:@"key"]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"You must first have a key for the masternode before you can configure it.";
        NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return;
    }
    if ([object valueForKey:@"transactionId"]) {
        [self configureStep2:object];
    } else {
    [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
        if (success) {
            NSMutableArray * outputs = [[[DPLocalNodeController sharedInstance] outputs] mutableCopy];
            NSArray * knownOutputs = [[[DPDataStore sharedInstance] allMasternodes] arrayOfArraysReferencedByKeyPaths:@[@"transactionId",@"transactionOutputIndex"] requiredKeyPaths:@[@"transactionId",@"transactionOutputIndex"]];
            for (int i = (int)[outputs count] -1;i> -1;i--) {
                for (NSArray * knownOutput in knownOutputs) {
                    if ([outputs[i][0] isEqualToString:knownOutput[0]] && ([outputs[i][1] integerValue] == [knownOutput[1] integerValue])) [outputs removeObjectAtIndex:i];
                }
            }
            if ([outputs count]) {
                [object setValue:outputs[0][0] forKey:@"transactionId"];
                [object setValue:@([outputs[0][1] integerValue])  forKey:@"transactionOutputIndex"];
                [[DPDataStore sharedInstance] saveContext];
                [self configureStep2:object];
            } else {
                NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                dict[NSLocalizedDescriptionKey] = @"No valid outputs (1000 DASH) in local wallet.";
                NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
                [[NSApplication sharedApplication] presentError:error];
                return;
            }
        } else {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = @"Dash server did not start.";
            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
            return;
        }
    }];
    
    }
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

        [[DPLocalNodeController sharedInstance] startRemote:object];
    
}

- (IBAction)startInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] startInstance:[object valueForKey:@"instanceId"]];
}


- (IBAction)stopInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] stopInstance:[object valueForKey:@"instanceId"]];
}

- (IBAction)terminateInstance:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    [[DPMasternodeController sharedInstance] terminateInstance:[object valueForKey:@"instanceId"]];
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

@end
