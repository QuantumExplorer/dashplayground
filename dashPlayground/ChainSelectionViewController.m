//
//  ChainSelectionViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 8/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "ChainSelectionViewController.h"
#import "DPChainSelectionController.h"
#import "DPMasternodeController.h"
#import "DPDataStore.h"

@interface ChainSelectionViewController ()

@property (weak) IBOutlet NSPopUpButton *chainPopUp;
@property (weak) IBOutlet NSTextField *chainNameField;
@property (weak) IBOutlet NSTextField *nameLabel;

@end

@implementation ChainSelectionViewController

ChainSelectionViewController* _chainSelectionWindow;
NSArray* _masternodeArrayObjects;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showChainSelectionWindow:(NSArray*)masternodes {
    if([_chainSelectionWindow.window isVisible]) return;
    _masternodeArrayObjects = masternodes;
    _chainSelectionWindow = [[ChainSelectionViewController alloc] initWithWindowNibName:@"ChainSelectionWindow"];
    [_chainSelectionWindow.window makeKeyAndOrderFront:self];
}

- (IBAction)pressOkButton:(id)sender {
    
    __block NSString *chainNetwork = @"";
    __block NSString *chainNetworkName = self.chainNameField.stringValue;
    
    if([self.chainPopUp.objectValue integerValue] == 0) {
        chainNetwork = @"mainnet";
    }
    else if([self.chainPopUp.objectValue integerValue] == 1) {
        chainNetwork = @"testnet";
    }
    else if([self.chainPopUp.objectValue integerValue] == 2) {
        //devnet=DRA -> this is local devnet name
        //TODO: find out a way to get local devnet name -> finished
        chainNetwork = [NSString stringWithFormat:@"devnet=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"chainNetworkName"]];
    }
    [_chainSelectionWindow close];
    
    dispatch_group_t d_group = dispatch_group_create();
    dispatch_queue_t bg_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    dispatch_group_async(d_group, bg_queue, ^{
        
        for(NSManagedObject *masternode in _masternodeArrayObjects)
        {
            if([[masternode valueForKey:@"isSelected"] integerValue] == 1) {
                [masternode setValue:chainNetwork forKey:@"chainNetwork"];
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];

                [[DPMasternodeController sharedInstance] setUpMasternodeConfiguration:masternode onChainName:chainNetworkName clb:^(BOOL success, NSString *message, BOOL isFinished) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:message];
                    });
//                    if(isFinished == YES) {
//                        [[DPLocalNodeController sharedInstance] stopDash:^(BOOL success, NSString *message) {
//                            if(success) {
//                                [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
//
//                                } forChain:chainNetwork];
//                            }
//                        } forChain:chainNetwork];
//                    }
                }];
            }
        }
    });
    
    dispatch_group_notify(d_group, dispatch_get_main_queue(), ^{
//        dispatch_release(d_group);
        [[DPLocalNodeController sharedInstance] stopDash:^(BOOL success, NSString *message) {
            if(success) {
                [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
                    
                } forChain:chainNetwork];
            }
        } forChain:chainNetwork];
    });
    
}

- (IBAction)selectChainNetwork:(id)sender {
    if([self.chainPopUp.objectValue integerValue] == 2) {
        self.nameLabel.hidden = false;
        self.chainNameField.hidden = false;
    }
    else {
        self.nameLabel.hidden = true;
        self.chainNameField.hidden = true;
    }
}



@end
