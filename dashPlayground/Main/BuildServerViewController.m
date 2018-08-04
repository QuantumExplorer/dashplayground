//
//  BuildServerViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 3/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "BuildServerViewController.h"
#import "DialogAlert.h"
#import "SshConnection.h"
#import "DPMasternodeController.h"
#import "ConsoleEventArray.h"
#import "DPBuildServerController.h"


@interface BuildServerViewController ()

@property (strong) IBOutlet NSTextField *buildServerIPText;
@property (strong) IBOutlet NSButton *connectButton;
@property (strong) IBOutlet NSTextField *buildServerStatusText;

@property (atomic) NMSSHSession* buildServerSession;

//Console
@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextField;

//Array Controller
@property (strong) IBOutlet NSArrayController *compileArrayController;
@property (strong) IBOutlet NSArrayController *downloadArrayController;
@property (strong) IBOutlet NSArrayController *commitArrayController;

//Table
@property (strong) IBOutlet NSTableView *compileTable;
@property (strong) IBOutlet NSTableView *downloadTable;
@property (strong) IBOutlet NSTableView *commitTable;


@end

@implementation BuildServerViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self initialize];
}

- (void)initialize {
    if([[[DPBuildServerController sharedInstance] getBuildServerIP] length] == 0) {
        self.buildServerIPText.stringValue = @"Unknown";
    }
    else {
        self.buildServerIPText.stringValue = [[DPBuildServerController sharedInstance] getBuildServerIP];
    }
    
    self.consoleEvents = [[ConsoleEventArray alloc] init];
    
    [DPBuildServerController sharedInstance].buildServerViewController = self;
    
    [self.commitTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
}

- (IBAction)changeServerIP:(id)sender {
    NSString *bsIP = [[DialogAlert sharedInstance] showAlertWithTextField:@"IP Address" message:@"Please input your build server public IP here."];
    
    if([bsIP length] > 0) {
        [[DPBuildServerController sharedInstance] setBuildServerIP:bsIP];
        self.buildServerIPText.stringValue = [[DPBuildServerController sharedInstance] getBuildServerIP];
    }
}

- (IBAction)connectBuildServer:(id)sender {
    
    if([self.connectButton.title isEqualToString:@"Connect"]) {
        [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:[[DPBuildServerController sharedInstance] getBuildServerIP] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(sshSession.isAuthorized) {
                self.buildServerSession = sshSession;
                
                self.buildServerStatusText.stringValue = @"Connected";
                self.buildServerStatusText.textColor = [NSColor systemGreenColor];
                
                self.connectButton.title = @"Disconnect";
                
                [self addStringEvent:@"Build server connected!"];
                
                NSMutableArray *repositoryArray = [[DPBuildServerController sharedInstance] getAllRepository:sshSession];
                [self showTableContent:repositoryArray onArrayController:self.downloadArrayController];
            }
            else {
                self.buildServerStatusText.stringValue = @"Disconnected";
                self.buildServerStatusText.textColor = [NSColor redColor];
                
                self.connectButton.title = @"Connect";
                
                [self addStringEvent:@"Failed connecting to build server!"];
            }
        }];
    }
    else {
        [self.buildServerSession disconnect];
        
        self.connectButton.title = @"Connect";
        
        self.buildServerStatusText.stringValue = @"Disconnected";
        self.buildServerStatusText.textColor = [NSColor redColor];
        
        [self.downloadArrayController setContent:nil];
        [self.commitArrayController setContent:nil];
        
        [self addStringEvent:@"Build server disconnected!"];
    }
}

- (IBAction)refresh:(id)sender {
    [self addStringEvent:@"Refreshing data..."];
    
    if([self.buildServerStatusText.stringValue isEqualToString:@"Connected"]) {
        [self.commitArrayController setContent:nil];
        NSMutableArray *repositoryArray = [[DPBuildServerController sharedInstance] getAllRepository:self.buildServerSession];
        [self showTableContent:repositoryArray onArrayController:self.downloadArrayController];
    }
}


-(void)addStringEvent:(NSString*)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([string length] == 0 || string == nil) return;
        ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
        [self.consoleEvents addConsoleEvent:consoleEvent];
        [self updateConsole];
    });
}

-(void)updateConsole {
    NSString * consoleEventString = [self.consoleEvents printOut];
    self.consoleTextField.string = consoleEventString;
}

-(void)showTableContent:(NSMutableArray*)contentArray onArrayController:(NSArrayController*)arrayController {
    
    [arrayController setContent:nil];
    for(NSDictionary *dict in contentArray) {
        [arrayController addObject:dict];
    }
    [arrayController rearrangeObjects];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.downloadTable.selectedRow;
    if(row == -1) {
        [self.commitArrayController setContent:nil];
        return;
    }
    NSManagedObject * object = [self.downloadArrayController.arrangedObjects objectAtIndex:row];
    
    if([[object valueForKey:@"commitInfo"] count] > 0) {
        [self showTableContent:[object valueForKey:@"commitInfo"] onArrayController:self.commitArrayController];
    }
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

@end
