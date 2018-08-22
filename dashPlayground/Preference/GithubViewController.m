//
//  GithubViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 17/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "GithubViewController.h"
#import "DPDataStore.h"

@interface GithubViewController ()

@property (strong) IBOutlet NSTextField *sshPathTextField;
@property (strong) IBOutlet NSSecureTextField *accessTokenTextField;


@end

@implementation GithubViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initialize];
}

- (void)initialize {
    if([[DPDataStore sharedInstance] getGithubAccessToken] != nil) self.accessTokenTextField.stringValue = [[DPDataStore sharedInstance] getGithubAccessToken];
    
    if([[DPDataStore sharedInstance] getGithubSshPath] != nil) self.sshPathTextField.stringValue = [[DPDataStore sharedInstance] getGithubSshPath];
}

- (IBAction)browseSshPath:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filePath = [openDlg URL].absoluteString;
        if([filePath length] >= 7) {
            filePath = [filePath substringFromIndex:7];
            self.sshPathTextField.stringValue = filePath;
        }
    }
}


- (IBAction)pressSave:(id)sender {
    if([self.accessTokenTextField.stringValue length] != 0) [[DPDataStore sharedInstance] setGithubAccessToken:self.accessTokenTextField.stringValue];
    if([self.sshPathTextField.stringValue length] != 0) [[DPDataStore sharedInstance] setGithubSshPath:self.sshPathTextField.stringValue];
    
    [self dismissController:sender];
}

@end
