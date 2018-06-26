//
//  DashCoreViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 21/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DashCoreViewController.h"
#import "DPLocalNodeController.h"
#import "DialogAlert.h"

@interface DashCoreViewController ()

@property (strong) IBOutlet NSTextField *dashCliField;
@property (strong) IBOutlet NSTextField *dashdField;
@property (strong) IBOutlet NSTextField *masternodeField;

@end

@implementation DashCoreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self initialize];
}

- (void)initialize {
    if([[DPLocalNodeController sharedInstance] dashCliPath] != nil) self.dashCliField.stringValue = [[DPLocalNodeController sharedInstance] dashCliPath];
    if([[DPLocalNodeController sharedInstance] dashDPath] != nil) self.dashdField.stringValue = [[DPLocalNodeController sharedInstance] dashDPath];
    if([[DPLocalNodeController sharedInstance] masterNodePath] != nil) self.masternodeField.stringValue = [[DPLocalNodeController sharedInstance] masterNodePath];
}

- (IBAction)browseDashCli:(id)sender {
    
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filePath = [openDlg URL].absoluteString;
        if([filePath length] >= 7) {
            filePath = [filePath substringFromIndex:7];
            self.dashCliField.stringValue = filePath;
        }
    }
}

- (IBAction)browseDashd:(id)sender {
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filePath = [openDlg URL].absoluteString;
        if([filePath length] >= 7) {
            filePath = [filePath substringFromIndex:7];
            self.dashdField.stringValue = filePath;
        }
    }
}

- (IBAction)browseMasternode:(id)sender {
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filePath = [openDlg URL].absoluteString;
        if([filePath length] >= 7) {
            filePath = [[filePath substringFromIndex:7] stringByRemovingPercentEncoding];
            self.masternodeField.stringValue = filePath;
        }
    }
}

- (IBAction)pressSave:(id)sender {
    if([self.dashCliField.stringValue length] != 0) [[DPLocalNodeController sharedInstance] setDashCliPath:self.dashCliField.stringValue];
    if([self.dashdField.stringValue length] != 0) [[DPLocalNodeController sharedInstance] setDashDPath:self.dashdField.stringValue];
    if([self.masternodeField.stringValue length] != 0) [[DPLocalNodeController sharedInstance] setMasterNodePath:self.masternodeField.stringValue];
    [self dismissController:sender];
}


@end
