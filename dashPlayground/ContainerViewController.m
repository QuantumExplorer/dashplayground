//
//  ContainerViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "ContainerViewController.h"
#import "Notification.h"
#import "DPLocalNodeController.h"
#import "DPDataStore.h"
#import "DialogAlert.h"

@interface ContainerViewController ()

@property (strong) IBOutlet NSPopUpButton *chainNetworkButton;
@property (strong) IBOutlet NSTextField *chainNameField;
@property (strong) IBOutlet NSUserDefaultsController *userDefaults;

@end

@implementation ContainerViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashdStopped:) name:nDASHD_STOPPED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashdStarted:) name:nDASHD_STARTED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dashdStarting:) name:nDASHD_STARTING object:nil];
}

- (IBAction)selectChainNetwork:(id)sender {
    
    DPDataStore *dataStore = [DPDataStore sharedInstance];
    
    self.chainNameField.hidden = true;
    if([self.chainNetworkButton.objectValue integerValue] == 0){
        dataStore.chainNetwork = @"mainnet";
    }
    else if([self.chainNetworkButton.objectValue integerValue] == 1){
        dataStore.chainNetwork = @"testnet";
    }
    else if([self.chainNetworkButton.objectValue integerValue] == 2){
        //devnet=DRA
        self.chainNameField.hidden = false;
        dataStore.chainNetwork = [NSString stringWithFormat:@"devnet=%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"chainNetworkName"]];
    }
}

- (IBAction)pressChainName:(id)sender {
    
    NSString *chainName = self.chainNameField.stringValue;
    [[NSUserDefaults standardUserDefaults] setObject:chainName forKey:@"chainNetworkName"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [[DialogAlert sharedInstance] showAlertWithOkButton:@"Chain Network" message:[NSString stringWithFormat:@"The chain network name was set to %@", self.chainNameField.stringValue]];
}


-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)dashdStopped:(NSNotification*)note {
    [self.dashRunningObserverImageView setImage:[NSImage imageNamed:@"Red_Light"]];
}

-(void)dashdStarted:(NSNotification*)note {
    [self.dashRunningObserverImageView setImage:[NSImage imageNamed:@"Green_Light"]];
}

-(void)dashdStarting:(NSNotification*)note {
    [self.dashRunningObserverImageView setImage:[NSImage imageNamed:@"Yellow_Light"]];
}
@end
