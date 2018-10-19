//
//  SshConnection.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 23/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "SshConnection.h"
#import <NMSSH/NMSSH.h>
#import "DialogAlert.h"
#import "DPMasternodeController.h"
#import "DashcoreStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"

@implementation SshConnection

-(void)sshInWithKeyPath:(NSString*)keyPath masternodeIp:(NSString*)masternodeIp openShell:(BOOL)shell clb:(dashSSHClb)clb {
    
    if (![[DPMasternodeController sharedInstance] sshPath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"SSH_KEY.pem" exPath:@"~/Documents"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [[DPMasternodeController sharedInstance] setSshPath:pathString];
            
            [self sshInWithKeyPath:pathString masternodeIp:masternodeIp openShell:shell clb:^(BOOL success, NSString *message, NMSSHSession *ssh) {
                clb(success, message, ssh);
            }];
        }
    }
    
    NMSSHSession *session = [NMSSHSession connectToHost:masternodeIp withUsername:@"ubuntu"];
    
    if (session.isConnected) {
        [session authenticateByPublicKey:nil privateKey:keyPath andPassword:nil];
        
        if (session.isAuthorized) {
            NSLog(@"Authentication succeeded");
            
            session.channel.ptyTerminalType = NMSSHChannelPtyTerminalAnsi;
            
            if(shell == YES)
            {
                session.channel.requestPty = YES;
                NSError *error = nil;
                [session.channel startShell:&error];
                if (error) {
                    clb(NO, [NSString stringWithFormat:@"SSH: error %@", [error localizedDescription]], session);
                }
                else {
                    clb(YES, @"SSH: authentication succeeded!", session);
                }
            }
            else {
                clb(YES, @"SSH: authentication succeeded!", session);
            }
        }
    }
}

#pragma mark - Connectivity

-(void)sendDashCommandsList:(NSArray*)commands onSSH:(NMSSHSession*)ssh onPath:(NSString*)path error:(NSError*)error dashClb:(dashMessageClb)clb {
    
    
    for (NSUInteger index = 0;index<[commands count];index++) {
        NSString * command = [commands objectAtIndex:index];
        
        NSMutableString *commandStr = [NSMutableString string];
        if (path) [commandStr appendString:path];
        [commandStr appendString:command];
        
//        NSString *string = [NSString stringWithFormat:@"executing command %@...", command];
//        clb(YES,string);
        
        __block BOOL isSucceed = YES;
        [self sendExecuteCommand:commandStr onSSH:ssh mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
            clb(success,message);
            isSucceed = success;
        }];
        if(!isSucceed) break;
        
        //        int currentCommand = (int)index;
        //        currentCommand = currentCommand+1;
        //        clb(command,(currentCommand*100)/[commands count]);
    }

}

-(void)sendWriteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    NSString *executeStr = [NSString stringWithFormat:@"executing command %@", command];
    
    error = nil;
    [ssh.channel write:command error:&error];
    if (error) {
        NSLog(@"SSH: error executing command %@ - %@", command, error);
        NSString *errorStr = [NSString stringWithFormat:@"SSH: error executing command %@ - %@", command, error];
        clb(errorStr,0);
        return;
    }
    else {
        clb(executeStr,0);
    }
}

-(void)sendExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh mainThread:(BOOL)mainThread dashClb:(dashClbWithError)clb {
    
    if(mainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //    NSString *executeStr = [NSString stringWithFormat:@"executing command %@", command];
            //    clb(YES, executeStr);
            //    [ssh.channel startShell:&error];
            __block NSError *error = nil;
            NSString *response = [ssh.channel execute:command error:&error];
            if (error) {
                //        NSLog(@"SSH: error executing command %@ - %@", command, [error localizedDescription]);
                NSString *errorStr = [NSString stringWithFormat:@"SSH: %@", [error localizedDescription]];
                clb(NO, errorStr,error);
                return;
            }
            else {
                //        NSLog(@"SSH: %@", response);
                clb(YES, response,nil);
            }
        });
    }
    else {
        //    NSString *executeStr = [NSString stringWithFormat:@"executing command %@", command];
        //    clb(YES, executeStr);
        //    [ssh.channel startShell:&error];
        __block NSError *error = nil;
        NSString *response = [ssh.channel execute:command error:&error];
        if (error) {
            //        NSLog(@"SSH: error executing command %@ - %@", command, [error localizedDescription]);
            NSString *errorStr = [NSString stringWithFormat:@"SSH: %@", [error localizedDescription]];
            clb(NO, errorStr,error);
            return;
        }
        else {
            //        NSLog(@"SSH: %@", response);
            clb(YES, response,error);
        }
    }
} 

//End Toey

#pragma mark - Singleton methods

+ (SshConnection *)sharedInstance
{
    static SshConnection *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SshConnection alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
