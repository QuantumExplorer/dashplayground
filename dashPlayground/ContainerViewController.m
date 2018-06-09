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

@interface ContainerViewController ()

@property (strong) IBOutlet NSPopUpButton *chainNetworkButton;

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
    
    if([self.chainNetworkButton.objectValue integerValue] == 0){
        dataStore.chainNetwork = @"mainnet";
    }
    else if([self.chainNetworkButton.objectValue integerValue] == 1){
        dataStore.chainNetwork = @"testnet";
    }
    else if([self.chainNetworkButton.objectValue integerValue] == 2){
        dataStore.chainNetwork = @"devnet=DRA";
    }
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
