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
                    clb(YES, [NSString stringWithFormat:@"SSH: error %@", [error localizedDescription]], session);
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

-(void)sendDashGitCloneCommandForRepositoryPath:(NSString*)repositoryPath toDirectory:(NSString*)directory onSSH:(NMSSHSession *)ssh error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    NSString *command = [NSString stringWithFormat:@"git clone %@ ~/src/dash",repositoryPath];
    [self sendWriteCommand:command onSSH:ssh error:error percentageClb:^(NSString *call, float percentage) {
        clb(call,0);
    }];
}

-(void)sendDashCommandsList:(NSArray*)commands onSSH:(NMSSHSession*)ssh onPath:(NSString*)path error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    NSMutableString *commandStr = [NSMutableString string];
    [commandStr appendString:path];
    
    for (NSUInteger index = 0;index<[commands count];index++) {
        NSString * command = [commands objectAtIndex:index];
        
        if((index+1) != [commands count]) {
            [commandStr appendString:[NSString stringWithFormat:@" %@;",command]];
        }
        else {
            [commandStr appendString:[NSString stringWithFormat:@" %@",command]];
        }
        
        //        int currentCommand = (int)index;
        //        currentCommand = currentCommand+1;
        //        clb(command,(currentCommand*100)/[commands count]);
    }
    
    error = nil;
    
    [self sendWriteCommand:commandStr onSSH:ssh error:error percentageClb:^(NSString *call, float percentage) {
        clb(call,0);
    }];
}

-(void)sendWriteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    NSString *string = [NSString stringWithFormat:@"executing command %@", command];
    
    error = nil;
    [ssh.channel write:command error:&error timeout:@100];
    if (error) {
        NSLog(@"SSH: error executing command %@ with reason %@", command, error);
        NSString *errorStr = [NSString stringWithFormat:@"SSH: error executing command %@ with reason %@", command, error];
        clb(errorStr,0);
        return;
    }
    else {
        clb(string,0);
    }
}

-(void)sendExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    NSString *string = [NSString stringWithFormat:@"executing command %@", command];
    
    error = nil;
    [ssh.channel execute:command error:&error];
    if (error) {
        NSLog(@"SSH: error executing command %@ with reason %@", command, [error localizedDescription]);
        NSString *errorStr = [NSString stringWithFormat:@"SSH: error executing command %@ with reason %@", command, [error localizedDescription]];
        clb(errorStr,0);
        return;
    }
    else {
        clb(string,0);
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
