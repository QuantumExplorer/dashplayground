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

@interface ChainSelectionViewController ()

@property (weak) IBOutlet NSPopUpButton *chainPopUp;
@property (weak) IBOutlet NSTextField *chainNameField;
@property (weak) IBOutlet NSTextField *nameLabel;

@end

@implementation ChainSelectionViewController

ChainSelectionViewController* _chainSelectionWindow;
NSManagedObject* _masternodeObject;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showChainSelectionWindow:(NSManagedObject*)masternode {
    if([_chainSelectionWindow.window isVisible]) return;
    _masternodeObject = masternode;
    _chainSelectionWindow = [[ChainSelectionViewController alloc] initWithWindowNibName:@"ChainSelectionWindow"];
    [_chainSelectionWindow.window makeKeyAndOrderFront:self];
}

- (IBAction)pressOkButton:(id)sender {
    NSString *chainNetwork = @"";
    if([self.chainPopUp.objectValue integerValue] == 0) {
        chainNetwork = @"mainnet";
    }
    else if([self.chainPopUp.objectValue integerValue] == 1) {
        chainNetwork = @"testnet";
    }
    else if([self.chainPopUp.objectValue integerValue] == 2) {
        chainNetwork = @"devnet";
    }
    
    [[DPMasternodeController sharedInstance] setUpMasternodeConfiguration:_masternodeObject clb:^(BOOL success, NSString *message) {
        if (!success) {
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = message;
            NSError * error = [NSError errorWithDomain:@"DASH_PLAYGROUND" code:10 userInfo:dict];
            [[NSApplication sharedApplication] presentError:error];
        }
//        [self addStringEventToMasternodeConsole:message];
    }];
    
    [[DPChainSelectionController sharedInstance] configureConfigDashFileForMasternode:_masternodeObject onChain:chainNetwork onName:self.chainNameField.stringValue];
    
}

@end
