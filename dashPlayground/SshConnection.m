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
#import "MasternodeStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"

@implementation SshConnection

-(void)sshInWithKeyPath:(NSString*)keyPath masternodeIp:(NSString*)masternodeIp openShell:(BOOL)shell clb:(dashSshClb)clb {
    
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

//Toey

-(void)sendDashGitCloneCommandForRepositoryPath:(NSString*)repositoryPath toDirectory:(NSString*)directory onSSH:(NMSSHSession *)ssh error:(NSError*)error dashClb:(dashClb)clb {
    
    NSString *command = [NSString stringWithFormat:@"git clone -b develop %@ ~/src/dash",repositoryPath];
    clb(YES,command);
    [self sendExecuteCommand:command onSSH:ssh error:error dashClb:^(BOOL success, NSString *call) {
        clb(success,call);
    }];
}

-(void)sendDashCommandsList:(NSArray*)commands onSSH:(NMSSHSession*)ssh onPath:(NSString*)path error:(NSError*)error dashClb:(dashClb)clb {
    
    
    for (NSUInteger index = 0;index<[commands count];index++) {
        NSString * command = [commands objectAtIndex:index];
        
        NSMutableString *commandStr = [NSMutableString string];
        [commandStr appendString:path];
        [commandStr appendString:command];
        
//        NSString *string = [NSString stringWithFormat:@"executing command %@...", command];
//        clb(YES,string);
        
        __block BOOL isSucceed = YES;
        [self sendExecuteCommand:commandStr onSSH:ssh error:error dashClb:^(BOOL success, NSString *message) {
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

-(void)sendExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error dashClb:(dashClb)clb {
    
    NSString *executeStr = [NSString stringWithFormat:@"executing command %@", command];
    clb(YES, executeStr);
//    [ssh.channel startShell:&error];
    error = nil;
    NSString *response = [ssh.channel execute:command error:&error];
    if (error) {
        NSLog(@"SSH: error executing command %@ - %@", command, [error localizedDescription]);
        NSString *errorStr = [NSString stringWithFormat:@"SSH: error executing command %@ - %@", command, [error localizedDescription]];
        clb(NO, errorStr);
        return;
    }
    else {
        NSLog(@"SSH: %@", response);
        clb(YES, response);
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
