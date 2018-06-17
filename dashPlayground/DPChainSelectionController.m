//
//  DPChainSelectionController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 8/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DPChainSelectionController.h"
#import "SshConnection.h"
#import "DPMasternodeController.h"

@implementation DPChainSelectionController

-(NSArray*)createNewConfigDashContent:(NMSSHSession*)ssh onChain:(NSString*)chain devnetName:(NSString*)devnetName onClb:(dashClb)clb {
    NSError *error = nil;
    NSArray *dashConfClone = [NSArray array];
    
    NSString *response = [ssh.channel execute:@"cd ~/.dashcore && cat dash.conf" error:&error];
    if(response != nil){
        NSArray *dashConf = [response componentsSeparatedByString:@"\n"];
        
        for(NSString *line in dashConf) {
//            if([line rangeOfString:@"devnet"].location != NSNotFound) {
//                clb(NO, @"This masternode is already on devnet!");
//                break;
//            }
            if ([line rangeOfString:@"mainnet"].location != NSNotFound
                || [line rangeOfString:@"testnet"].location != NSNotFound)
            {
                NSString *newLine = [NSString stringWithFormat:@"%@=%@",chain ,devnetName];
                dashConfClone = [dashConfClone arrayByAddingObject:newLine];
            }
            else if ([line rangeOfString:@"rpcport"].location != NSNotFound)
            {
                NSString *newLine = @"rpcport=12998";
                dashConfClone = [dashConfClone arrayByAddingObject:newLine];
            }
            else {
                dashConfClone = [dashConfClone arrayByAddingObject:line];
            }
        }
        dashConfClone = [dashConfClone arrayByAddingObject:@"port=12999"];
        dashConfClone = [dashConfClone arrayByAddingObject:@"sporkaddr=ycocX7F7MEQWpoNaJ7mjYHEPNt2N1Zp1V5"];
        dashConfClone = [dashConfClone arrayByAddingObject:@"sporkkey=cREWeXYwFMWSnLtrC1osjjf3TXBZX95xZhMRgPQu76BWqdiNbqeM"];
    }
    return dashConfClone;
}

-(void)configureConfigDashFileForMasternode:(NSManagedObject*)masternode onChain:(NSString*)chain onName:(NSString*)devName onClb:(dashClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            
            clb(YES, @"updating dash.conf file...");
            
            if(success != YES) return;
            
            __block BOOL isSuccess = YES;
            NSError *error = nil;
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore" onSSH:sshSession error:error dashClb:^(BOOL success, NSString *message) {
                isSuccess = success;
            }];
            if(isSuccess != YES) return;
            
            NSArray *dashConfContents = [self createNewConfigDashContent:sshSession onChain:chain devnetName:devName onClb:^(BOOL success, NSString *message) {
                isSuccess = success;
            }];
            if(isSuccess != YES) return;
            
            NSString *localFilePath = [self createDashConfFile:dashConfContents];
            NSString *remoteFilePath = @"/home/ubuntu/.dashcore/dash.conf";
            BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
            if (uploadSuccess != YES) {
                NSLog(@"%@",[[sshSession lastError] localizedDescription]);
            }
            
        }];
    });
}

-(NSString*)createDashConfFile:(NSArray*)contents {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/dash",
                          documentsDirectory];
    //create content - four lines of text
    NSMutableString *content = [NSMutableString string];
    for(NSString *line in contents) {
        [content appendString:[NSString stringWithFormat:@"%@\n", line]];
    }
    //save content to the documents directory
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
    return fileName;
}

-(void)executeConfigurationMethod:(NSString*)chainNetwork onName:(NSString*)chainNetworkName onMasternode:(NSManagedObject*)masternode {
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) chainNetwork = @"devnet";
    [[DPChainSelectionController sharedInstance] configureConfigDashFileForMasternode:masternode onChain:chainNetwork onName:chainNetworkName onClb:^(BOOL success, NSString *message) {
        if(success != YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:@"configure chain network failed."];
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:@"configure chain network successfully."];
            });
        }
    }];
}

#pragma mark - Singleton methods

+ (DPChainSelectionController *)sharedInstance
{
    static DPChainSelectionController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPChainSelectionController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
