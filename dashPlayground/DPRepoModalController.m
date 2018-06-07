//
//  DPRepoModalController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 9/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "DPRepoModalController.h"
#import "MasternodesViewController.h"
#import <NMSSH/NMSSH.h>
#import "DialogAlert.h"
#import "MasternodeStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"
#import "DPDataStore.h"
#import "DPLocalNodeController.h"
#import "DPMasternodeController.h"
#import "SshConnection.h"

@implementation DPRepoModalController

MasternodesViewController *masternodeCon;

#pragma mark - Set Up

-(void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb
{
    
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    __block NSString * repositoryPath = [repository valueForKey:@"repository.url"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        __block NMSSHSession *ssh;
        [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            ssh = sshSession;
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternodeCon addStringEventToMasternodeConsole:message];
            });
        }];
        
        if (!ssh.isAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternodeCon addStringEventToMasternodeConsole:@"SSH: error authenticating with server."];
            });
            return;
        }
        
        NSError *error = nil;
        [ssh.channel write:@"cd src" error:&error];
        if (error) {
            error = nil;
            [ssh.channel write:@"mkdir src" error:&error];
            if(error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *erroStr = [NSString stringWithFormat:@"SSH: error making src directory. %@", error.localizedDescription];
                    [masternodeCon addStringEventToMasternodeConsole:erroStr];
                    clb(NO,erroStr);
                });
                return;
            }
        }
        
        //clone repository
        [[SshConnection sharedInstance] sendDashGitCloneCommandForRepositoryPath:repositoryPath toDirectory:@"~/src/dash" onSSH:ssh error:error dashClb:^(BOOL success, NSString *call) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(success == YES) {
                    [masternodeCon addStringEventToMasternodeConsole:@"git clone successfully."];
                }
                else {
                    [masternodeCon addStringEventToMasternodeConsole:call];
                }
                [masternode setValue:repositoryPath forKey:@"repositoryUrl"];
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            });
        }];
        
        //now let's make all this shit
        __block BOOL isSuccess = YES;
        [[SshConnection sharedInstance] sendDashCommandsList:@[@"autogen.sh",@"configure"] onSSH:ssh onPath:@"~/src/dash/" error:error dashClb:^(BOOL success, NSString *call) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternodeCon addStringEventToMasternodeConsole:call];
                if(success == NO) {
                    isSuccess = NO;
                    return;
                }
            });
        }];
        
        [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src; make --file=~/src/Makefile" onSSH:ssh error:error dashClb:^(BOOL success, NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternodeCon addStringEventToMasternodeConsole:message];
                if(success == NO) {
                    isSuccess = NO;
                    return;
                }
            });
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(isSuccess == NO) {
                [masternode setValue:@(MasternodeState_SettingUp) forKey:@"masternodeState"];
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                [[DialogAlert sharedInstance] showWarningAlert:@"Set up" message:@"Set up failed!"];
                return;
            }
            [ssh disconnect];
            [masternodeCon addStringEventToMasternodeConsole:[NSString stringWithFormat:@"SSH: disconnected from %@", publicIP]];
            [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            [[DialogAlert sharedInstance] showAlertWithOkButton:@"Set up" message:@"Set up successfully!"];
        });
        

        //---------
    });
    
    
}

-(void)setViewController:(MasternodesViewController*)controller {
    masternodeCon = controller;
}

-(NSMutableArray*)getRepositoriesData {
    NSArray *repoData = [[DPDataStore sharedInstance] allRepositories];
    NSMutableArray * repositoryArray = [NSMutableArray array];
    
    NSUInteger count = [repoData count];
    for (NSUInteger i = 0; i < count; i++) {
        //repository entity
        NSManagedObject *repository = (NSManagedObject *)[repoData objectAtIndex:i];
        //branch entity
        NSManagedObject *branch = (NSManagedObject *)[repository valueForKey:@"branches"];
        
        NSDictionary * rDict = [NSMutableDictionary dictionary];
        
        [rDict setValue:[repository valueForKey:@"url"] forKey:@"repository.url"];
        [rDict setValue:[[branch valueForKey:@"name"] anyObject] forKey:@"branchName"];
        
        [repositoryArray addObject:rDict];
    }
    
    
    return repositoryArray;
}

#pragma mark - Singleton methods

+ (DPRepoModalController *)sharedInstance
{
    static DPRepoModalController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPRepoModalController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
