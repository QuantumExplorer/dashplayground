//
//  DPNetworkController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 25/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DPNetworkController.h"
#import "PreferenceData.h"
#import "DPMasternodeController.h"
#import "SshConnection.h"
#import "DebugTypeTransformer.h"
#import "DPDataStore.h"

@implementation DPNetworkController

-(void)getDebugLogFileFromMasternode:(NSManagedObject*)masternode clb:(dashMessageClb)clb {
    __block NSString *publicIP = [masternode valueForKey:@"publicIP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(!sshSession.authorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,@"Could not SSH in");
                });
                return;
            }
            
            NSString *command = @"cd ~/.dashcore/testnet3 && cat debug.log";
            if ([[masternode valueForKey:@"chainNetwork"] rangeOfString:@"devnet"].location != NSNotFound) {
                NSArray * components = [[masternode valueForKey:@"chainNetwork"] componentsSeparatedByString:@"="];
                if([components count] >= 2) {
                    command = [NSString stringWithFormat:@"cd ~/.dashcore/devnet-%@ && cat debug.log", components[1]];
                }
            }
            
            NSError *error;
            NSString *response = [sshSession.channel execute:command error:&error];
            clb(YES, response);
        }];
    });
}

- (void)findSpecificDataType:(NSString*)log datatype:(NSString*)type onClb:(dashMessageClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        NSArray *logSubLine = [log componentsSeparatedByString:@"\n"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains %@", type];
        NSArray *list = [logSubLine filteredArrayUsingPredicate:predicate];
        
        if([list count] == 0) {
            clb(YES, @"Not found!");
        }
        else {
            NSString * result = [list componentsJoinedByString:@"\n"];
            clb(YES, result);
        }
        
    });
}

#pragma mark - Singleton methods

+ (DPNetworkController *)sharedInstance
{
    static DPNetworkController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPNetworkController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
