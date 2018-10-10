//
//  DPVersioningController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 30/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DPVersioningController.h"
#import "DPLocalNodeController.h"
#import "DPMasternodeController.h"
#import "DPDataStore.h"
#import "SshConnection.h"
#import "DPBuildServerController.h"
#import "Masternode+CoreDataClass.h"
#import "DPAuthenticationManager.h"
#import "DialogAlert.h"
#import "Branch+CoreDataClass.h"
#import "Masternode+CoreDataClass.h"
#import "DAPIStateTransformer.h"
#import "DashDriveStateTransformer.h"
#import "SentinelStateTransformer.h"
#import "InsightStateTransformer.h"

@implementation DPVersioningController

- (void)fetchGitCommitInfoOnMasternode:(Masternode*)masternode forProject:(DPRepositoryProject)project clb:(dashArrayClb)clb {
    Branch * branch = [masternode branchForProject:project];
    Repository * repository = branch.repository;
    if (!branch || !repository) {
        clb(NO,nil);
        return;
    }
    
    NSDictionary *gitCommitDictionary = [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/commits?sha=%@", repository.owner, repository.name, branch.name] checkError:NO];
    
    //if not found, let's assume this repository is private
    if([gitCommitDictionary count] == 2 && [[gitCommitDictionary valueForKey:@"message"] isEqualToString:@"Not Found"]) {
        
        //Pop up to ask for Github username and password
        
        [[DPAuthenticationManager sharedInstance] authenticateWithClb:^(BOOL authenticated, NSString *githubUsername, NSString *githubPassword) {
            if (!authenticated) return;
            NSDictionary *gitCommitDictionary = [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"-u %@:%@ https://api.github.com/repos/%@/%@/commits?sha=%@",githubUsername, githubPassword, repository.owner, repository.name, branch.name] checkError:NO];
            
            //if user put wrong username/password then reset attributes and do nothing
            if([gitCommitDictionary count] == 2 && [[gitCommitDictionary valueForKey:@"message"] isEqualToString:@"Bad credentials"]) {
                //todo deal with bad credentials
                [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Wrong username or password."];
            }
            else {//if authentication passed
                clb(YES,[self splitGitCommitArrayData:gitCommitDictionary]);
            }
        }];
        
    }
    else {//if everything's ok
        clb(YES,[self splitGitCommitArrayData:gitCommitDictionary]);
    }
    
    
}

- (NSMutableArray*)splitGitCommitArrayData:(NSDictionary*)dict {
    NSMutableArray *gitCommitArray = [NSMutableArray array];
    
    int countObject = 0;
    for(NSArray *commitObject in dict)
    {
        if(countObject == 10) break;
        countObject = countObject+1;
        
        NSString *message;
        if([[[commitObject valueForKey:@"commit"] valueForKey:@"message"] length] > 20) {
            message = [NSString stringWithFormat:@"%@...", [[[commitObject valueForKey:@"commit"] valueForKey:@"message"] substringToIndex:20] ];
        }
        else{
            message = [NSString stringWithFormat:@"%@", [[commitObject valueForKey:@"commit"] valueForKey:@"message"]];
        }
        
        NSString *date = [NSString stringWithFormat:@"%@", [[[commitObject valueForKey:@"commit"] valueForKey:@"author"] valueForKey:@"date"]];
        
        NSString *sha = [NSString stringWithFormat:@"%@", [commitObject valueForKey:@"sha"]];
        
        NSString *data = [NSString stringWithFormat:@"%@, Date: %@, Message: %@", sha, date, message];
        
        [gitCommitArray addObject:data];
    }
    
    return gitCommitArray;
}

- (void)updateCore:(NSString*)publicIP repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch commitHead:(NSString*)commitHead {
    if([repositoryUrl length] > 1 && [gitBranch length] > 1) {
        repositoryUrl = [repositoryUrl stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSArray *repoArray = [repositoryUrl componentsSeparatedByString:@"/"];
        
        if([repoArray count] == 5) {
            NSString *gitOwner = [repoArray objectAtIndex:3];
            NSString *gitRepo = [repoArray objectAtIndex:4];
            gitRepo = [gitRepo substringToIndex:[gitRepo length] - 4];
            
            __block NSString *downloadDashCliCommand = [NSString stringWithFormat:@"wget http://%@/core/%@-%@/%@/%@/dash-cli", [[DPBuildServerController sharedInstance] getBuildServerIP], gitOwner, gitRepo, gitBranch, commitHead];
            __block NSString *downloadDashDCommand = [NSString stringWithFormat:@"wget http://%@/core/%@-%@/%@/%@/dashd", [[DPBuildServerController sharedInstance] getBuildServerIP], gitOwner, gitRepo, gitBranch, commitHead];
            
            
            [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                if(success == YES) {
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                        
                        __block BOOL isAllowedToContiunue = NO;
                        
                        NSError *error = nil;
                        NSString *downloadCommand = [NSString stringWithFormat:@"cd ~/src/dash/src/ && %@", downloadDashCliCommand];
                        
                        [self.delegate versionControllerRelayMessage:@"Downloading dash-cli..."];
                        [[SshConnection sharedInstance] sendExecuteCommand:downloadCommand onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                            NSLog(@"%@", message);
                            
                            if([message length] == 0) {
                                [self.delegate versionControllerRelayMessage:@"Downloaded dash-cli successfully!"];
                            }
                            else {
                                [self.delegate versionControllerRelayMessage:message];
                            }
                            isAllowedToContiunue = success;
                        }];
                        
                        if(isAllowedToContiunue == NO) return;
                        
                        downloadCommand = [NSString stringWithFormat:@"cd ~/src/dash/src/ && %@", downloadDashDCommand];
                        [self.delegate versionControllerRelayMessage:@"Downloading dashd..."];
                        [[SshConnection sharedInstance] sendExecuteCommand:downloadCommand onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                            NSLog(@"%@", message);
                            
                            if([message length] == 0) {
                                [self.delegate versionControllerRelayMessage:@"Downloaded dashd successfully!"];
                            }
                            else {
                                [self.delegate versionControllerRelayMessage:message];
                            }
                            isAllowedToContiunue = success;
                        }];
                        
                        if(isAllowedToContiunue == YES) {
                            NSString *command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dash-cli"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                                
                            }];
                            
                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dash-cli.1 dash-cli && chmod +x dash-cli"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                                
                            }];
                            
                            //dashd
                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dashd"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                                
                            }];
                            
                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dashd.1 dashd && chmod +x dashd"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                                
                            }];
                        }
                    });
                }
            }];
        }
    }
    else {
        [self.delegate versionControllerRelayMessage:@"Error! There is some missing attributes. Please refresh and try again."];
    }
}

-(void)updateDapi:(NSString*)publicIP repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch commitHead:(NSString*)commitHead {
    if([repositoryUrl length] > 1 && [gitBranch length] > 1) {
        repositoryUrl = [repositoryUrl stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSArray *repoArray = [repositoryUrl componentsSeparatedByString:@"/"];
        
        if([repoArray count] == 5) {
            NSString *gitOwner = [repoArray objectAtIndex:3];
            NSString *gitRepo = [repoArray objectAtIndex:4];
            gitRepo = [gitRepo substringToIndex:[gitRepo length] - 4];
            
            
            
            
            [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                if(success == YES) {
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                        NSString *checkDapiCommand = [NSString stringWithFormat:@"ls ~/src/"];
                        NSError *error = nil;
                        
                        
                        [self.delegate versionControllerRelayMessage:@"Checking to see if DAPI is installed"];
                        
                        [[SshConnection sharedInstance] sendExecuteCommand:checkDapiCommand onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                            NSLog(@"%@", message);
                            
                            if([message length] == 0) {
                                [self.delegate versionControllerRelayMessage:@"Downloaded dash-cli successfully!"];
                            }
                            else {
                                [self.delegate versionControllerRelayMessage:message];
                            }
                            
                            NSString *gitCloneCommand = [NSString stringWithFormat:@"cd ~/src/ && git clone %@", repositoryUrl];
                            [[SshConnection sharedInstance] sendExecuteCommand:gitCloneCommand onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                                NSLog(@"%@", message);
                                
                                if([message length] == 0) {
                                    [self.delegate versionControllerRelayMessage:@"Downloaded dash-cli successfully!"];
                                }
                                else {
                                    [self.delegate versionControllerRelayMessage:message];
                                }
                            }];
                        }];
                        
                        
                        
                        
                        
                        //                        NSString *checkDapiCommand = [NSString stringWithFormat:@"cd ~/src/dash/src/ && %@", downloadDashDCommand];
                        //                        [self.delegate versionControllerRelayMessage:@"Downloading dashd..."];
                        //                        [[SshConnection sharedInstance] sendExecuteCommand:downloadCommand onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                        //                            NSLog(@"%@", message);
                        //
                        //                            if([message length] == 0) {
                        //                                [self.delegate versionControllerRelayMessage:@"Downloaded dashd successfully!"];
                        //                            }
                        //                            else {
                        //                                [self.delegate versionControllerRelayMessage:message];
                        //                            }
                        //                            isAllowedToContiunue = success;
                        //                        }];
                        //
                        //                        if(isAllowedToContiunue == YES) {
                        //                            NSString *command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dash-cli"];
                        //
                        //                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                        //
                        //                            }];
                        //
                        //                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dash-cli.1 dash-cli && chmod +x dash-cli"];
                        //
                        //                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                        //
                        //                            }];
                        //
                        //                            //dashd
                        //                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dashd"];
                        //
                        //                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                        //
                        //                            }];
                        //
                        //                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dashd.1 dashd && chmod +x dashd"];
                        //
                        //                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                        //
                        //                            }];
                        //                        }
                    });
                }
            }];
        }
    }
    else {
        [self.delegate versionControllerRelayMessage:@"Error! There is some missing attributes. Please refresh and try again."];
    }
}


#pragma mark - Dapi

-(void)updateProject:(DPRepositoryProject)project toLatestCommitInBranch:(Branch*)branch onMasternode:(Masternode*)masternode clb:(dashErrorClb)dashClb {
    if (!masternode) return;
    __block NSString * repositoryPath;
    [[DPAuthenticationManager sharedInstance] authenticateWithClb:^(BOOL authenticated, NSString *githubUsername, NSString *githubPassword) {
        if (branch.repository.isPrivate) {
            NSArray *pathComponents = [branch.repository.url componentsSeparatedByString:@"//"];
            if([pathComponents count] < 2) {
                return;
            }
            repositoryPath = [NSString stringWithFormat:@"https://%@:%@@%@", githubUsername, githubPassword, pathComponents[1]];
        } else {
            repositoryPath = branch.repository.url;
        }
        __block NSString * branchName = branch.name;
        [[DPMasternodeController sharedInstance] createBackgroundSSHSessionOnMasternode:masternode clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if (!success) {
                dashClb(NO,nil);
                return;
            }
            [[DPMasternodeController sharedInstance] installDependenciesForMasternode:masternode inSession:sshSession withClb:^(BOOL success, BOOL installed) {
                if (!success) {
                    dashClb(NO,nil);
                    return;
                }
                NSString * directory = [NSString stringWithFormat:@"~/src/%@",[ProjectTypeTransformer directoryForProject:project]];
                [[DPMasternodeController sharedInstance] gitCloneProjectWithRepositoryPath:repositoryPath toDirectory:directory andSwitchToBranch:branchName inSSHSession:sshSession dashClb:^(BOOL success, NSString *message) {
                    if (!success) {
                        dashClb(NO,nil);
                        return;
                    }
                    NSLog(@"%@ successfully cloned",[[[ProjectTypeTransformer alloc] init] transformedValue:@(project)]);
                    [[DPMasternodeController sharedInstance] updateGitInfoForMasternode:masternode forProject:project clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                        if (!success) {
                            dashClb(NO,nil);
                            return;
                        }
                        switch (project) {
                            case DPRepositoryProject_Dapi:
                            {
                                [masternode.managedObjectContext performBlockAndWait:^{
                                    masternode.dapiState = DPDapiState_Installed | masternode.dapiState;
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }];
                                break;
                            }
                            case DPRepositoryProject_Drive:
                            {
                                [masternode.managedObjectContext performBlockAndWait:^{
                                    masternode.driveState = DPDriveState_Installed | masternode.driveState;
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }];
                                break;
                            }
                            case DPRepositoryProject_Insight:
                            {
                                [masternode.managedObjectContext performBlockAndWait:^{
                                    masternode.insightState = DPInsightState_Installed | masternode.insightState;
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }];
                                break;
                            }
                            case DPRepositoryProject_Sentinel:
                            {
                                [masternode.managedObjectContext performBlockAndWait:^{
                                    masternode.sentinelState = DPSentinelState_Installed | masternode.sentinelState;
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }];
                                break;
                            }
                            default:
                                break;
                        }
                        dashClb(YES,nil);
                    }];
                }];
            }];
        }];
    }];
}

#pragma mark - Singleton methods

+ (DPVersioningController *)sharedInstance
{
    static DPVersioningController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPVersioningController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}
@end
