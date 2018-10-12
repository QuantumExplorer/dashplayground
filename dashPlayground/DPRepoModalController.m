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
#import "DashcoreStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"
#import "DPDataStore.h"
#import "DPLocalNodeController.h"
#import "DPMasternodeController.h"
#import "SshConnection.h"
#import "DPAuthenticationManager.h"
#import "Repository+CoreDataClass.h"
#import "Masternode+CoreDataClass.h"

@implementation DPRepoModalController

MasternodesViewController *masternodeCon;

#pragma mark - Set Up

-(void)setUpMasternodeDashdWithSelectedRepo:(Masternode*)masternode repository:(Repository*)repository clb:(dashMessageClb)clb
{
    [[DPAuthenticationManager sharedInstance] authenticateWithClb:^(BOOL authenticated, NSString *githubUsername, NSString *githubPassword) {
        if (!authenticated) return;
        __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
        __block NSString * repositoryPath = [repository valueForKey:@"repository.url"];
        __block NSString * branchName = [repository valueForKey:@"branchName"];
        __block NSUInteger repoType = [[repository valueForKey:@"repoType"] integerValue];
        
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            

            [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                if (!success || !sshSession) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternodeCon addStringEventToMasternodeConsole:message];
                });
                if (!sshSession.isAuthorized) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternodeCon addStringEventToMasternodeConsole:@"SSH: error authenticating with server."];
                    });
                    return;
                }
                
                NSError *error = nil;
                [sshSession.channel write:@"cd src" error:&error];
                if (error) {
                    error = nil;
                    [sshSession.channel write:@"mkdir src" error:&error];
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
                if(repoType == 1) {//private repository
                    NSArray *pathComponents = [repositoryPath componentsSeparatedByString:@"//"];
                    if([pathComponents count] < 2) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [masternodeCon addStringEventToMasternodeConsole:@"Error: something went wrong with repository path."];
                        });
                        return;
                    }
                    repositoryPath = [NSString stringWithFormat:@"https://%@:%@@%@", githubUsername, githubPassword, pathComponents[1]];
                }
                
                [[DPMasternodeController sharedInstance] gitCloneProjectWithRepositoryPath:repositoryPath toDirectory:@"~/src/dash" andSwitchToBranch:branchName inSSHSession:sshSession dashClb:^(BOOL success, NSString *message) {
                    if (!success) {
                        [sshSession disconnect];
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternodeCon addStringEventToMasternodeConsole:message];
                    });
                    
                    //now let's make all this shit
                    [[SshConnection sharedInstance] sendDashCommandsList:@[@"autogen.sh",@"configure"] onSSH:sshSession onPath:@"~/src/dash/" error:error dashClb:^(BOOL success, NSString *call) {
                        if (!success) {
                            [sshSession disconnect];
                            return;
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [masternodeCon addStringEventToMasternodeConsole:call];
                        });
                        [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                            [sshSession disconnect];
                            if (!success) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternodeCon addStringEventToMasternodeConsole:[NSString stringWithFormat:@"SSH: disconnected from %@", publicIP]];
                                    masternode.dashcoreState = DPDashcoreState_SettingUp;
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                    [[DialogAlert sharedInstance] showWarningAlert:@"Set up" message:@"Set up failed!"];
                                });
                                return;
                            }
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [masternodeCon addStringEventToMasternodeConsole:message];
                                    masternode.dashcoreState = DPDashcoreState_SettingUp;
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                [[DialogAlert sharedInstance] showAlertWithOkButton:@"Set up" message:@"Set up successfully!"];
                            });
                        }];
                        
                        
                    }];
                    
                    
                }];
            }];
            
            
            
            
            
            
            //---------
        });
        
    }];
    
    
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
        
        if([[branch valueForKey:@"name"] count] == 0) continue;
        
        NSDictionary * rDict = [NSMutableDictionary dictionary];
        
        [rDict setValue:[repository valueForKey:@"url"] forKey:@"repository.url"];
        [rDict setValue:[[branch valueForKey:@"name"] anyObject] forKey:@"branchName"];
        [rDict setValue:[[branch valueForKey:@"repoType"] anyObject] forKey:@"repoType"];
        
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
