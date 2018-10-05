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
#import "DialogAlert.h"
#import "DPDataStore.h"
#import "SshConnection.h"
#import "VersioningViewController.h"
#import "DPBuildServerController.h"

@implementation DPVersioningController

@synthesize versioningViewController = _versioningViewController;

- (NSMutableArray*)getGitCommitInfo:(NSManagedObject*)masternode repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch {
    
    if([repositoryUrl length] > 1 && [gitBranch length] > 1) {
        repositoryUrl = [repositoryUrl stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSArray *repoArray = [repositoryUrl componentsSeparatedByString:@"/"];
        
        if([repoArray count] == 5) {
            NSString *gitOwner = [repoArray objectAtIndex:3];
            NSString *gitRepo = [repoArray objectAtIndex:4];
            gitRepo = [gitRepo substringToIndex:[gitRepo length] - 4];
            
            NSDictionary *gitCommitDic = [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/commits?sha=%@", gitOwner, gitRepo, gitBranch] checkError:NO];
            
            //if not found, let's assume this repository is private
            if([gitCommitDic count] == 2 && [[gitCommitDic valueForKey:@"message"] isEqualToString:@"Not Found"]) {
                
                //Pop up to ask for Github username and password
                
                if([[[DPDataStore sharedInstance] githubUsername] length] <= 1 || [[[DPDataStore sharedInstance] githubPassword] length] <= 1) {
                    [DPDataStore sharedInstance].githubUsername = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github username" message:@"Please enter your Github username" placeHolder:@""];
                    [DPDataStore sharedInstance].githubPassword = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github password" message:@"Please enter your Github password"];
                }
                
                if([[[DPDataStore sharedInstance] githubUsername] length] <= 1 || [[[DPDataStore sharedInstance] githubPassword] length] <= 1) return nil;
                
                gitCommitDic = [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"-u %@:%@ https://api.github.com/repos/%@/%@/commits?sha=%@",[[DPDataStore sharedInstance] githubUsername], [[DPDataStore sharedInstance] githubPassword], gitOwner, gitRepo, gitBranch] checkError:NO];
                
                //if user put wrong username/password then reset attributes and do nothing
                if([gitCommitDic count] == 2 && [[gitCommitDic valueForKey:@"message"] isEqualToString:@"Bad credentials"]) {
                    [DPDataStore sharedInstance].githubUsername = @"";
                    [DPDataStore sharedInstance].githubPassword = @"";
                    [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Wrong username or password."];
                }
                else {//if authentication passed
                    return [self getGitCommitArrayData:gitCommitDic];
                }
                
            }
            else {//if everything's ok
                return [self getGitCommitArrayData:gitCommitDic];
            }
        }
        else {
            //this instance might install repository incorrent.
            [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Could not access to this repository."];
        }
    }
    else {//if this object has no attributes then update
        [[DPMasternodeController sharedInstance] updateMasternodeAttributes:masternode];
        [self getGitCommitInfo:masternode repositoryUrl:repositoryUrl onBranch:gitBranch];
    }
    
    return nil;
}

- (NSMutableArray*)getGitCommitArrayData:(NSDictionary*)dict {
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
                        
                        [self.versioningViewController addStringEvent:@"Downloading dash-cli..."];
                        [[SshConnection sharedInstance] sendExecuteCommand:downloadCommand onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                            NSLog(@"%@", message);
                            
                            if([message length] == 0) {
                                [self.versioningViewController addStringEvent:@"Downloaded dash-cli successfully!"];
                            }
                            else {
                                [self.versioningViewController addStringEvent:message];
                            }
                            isAllowedToContiunue = success;
                        }];
                        
                        if(isAllowedToContiunue == NO) return;
                        
                        downloadCommand = [NSString stringWithFormat:@"cd ~/src/dash/src/ && %@", downloadDashDCommand];
                        [self.versioningViewController addStringEvent:@"Downloading dashd..."];
                        [[SshConnection sharedInstance] sendExecuteCommand:downloadCommand onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                            NSLog(@"%@", message);
                            
                            if([message length] == 0) {
                                [self.versioningViewController addStringEvent:@"Downloaded dashd successfully!"];
                            }
                            else {
                                [self.versioningViewController addStringEvent:message];
                            }
                            isAllowedToContiunue = success;
                        }];
                        
                        if(isAllowedToContiunue == YES) {
                            NSString *command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dash-cli"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                                
                            }];
                            
                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dash-cli.1 dash-cli && chmod +x dash-cli"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                                
                            }];
                            
                            //dashd
                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dashd"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                                
                            }];
                            
                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dashd.1 dashd && chmod +x dashd"];
                            
                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                                
                            }];
                        }
                    });
                }
            }];
        }
    }
    else {
        [self.versioningViewController addStringEvent:@"Error! There is some missing attributes. Please refresh and try again."];
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
                        
                        
                        [self.versioningViewController addStringEvent:@"Checking to see if DAPI is installed"];
                        
                        [[SshConnection sharedInstance] sendExecuteCommand:checkDapiCommand onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                            NSLog(@"%@", message);
                            
                            if([message length] == 0) {
                                [self.versioningViewController addStringEvent:@"Downloaded dash-cli successfully!"];
                            }
                            else {
                                [self.versioningViewController addStringEvent:message];
                            }
                            
                            NSString *gitCloneCommand = [NSString stringWithFormat:@"cd ~/src/ && git clone %@", repositoryUrl];
                            [[SshConnection sharedInstance] sendExecuteCommand:gitCloneCommand onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                                NSLog(@"%@", message);
                                
                                if([message length] == 0) {
                                    [self.versioningViewController addStringEvent:@"Downloaded dash-cli successfully!"];
                                }
                                else {
                                    [self.versioningViewController addStringEvent:message];
                                }
                            }];
                        }];
                        
                        
                        

                        
//                        NSString *checkDapiCommand = [NSString stringWithFormat:@"cd ~/src/dash/src/ && %@", downloadDashDCommand];
//                        [self.versioningViewController addStringEvent:@"Downloading dashd..."];
//                        [[SshConnection sharedInstance] sendExecuteCommand:downloadCommand onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
//                            NSLog(@"%@", message);
//
//                            if([message length] == 0) {
//                                [self.versioningViewController addStringEvent:@"Downloaded dashd successfully!"];
//                            }
//                            else {
//                                [self.versioningViewController addStringEvent:message];
//                            }
//                            isAllowedToContiunue = success;
//                        }];
//
//                        if(isAllowedToContiunue == YES) {
//                            NSString *command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dash-cli"];
//
//                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
//
//                            }];
//
//                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dash-cli.1 dash-cli && chmod +x dash-cli"];
//
//                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
//
//                            }];
//
//                            //dashd
//                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && rm -r dashd"];
//
//                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
//
//                            }];
//
//                            command = [NSString stringWithFormat:@"cd ~/src/dash/src/ && mv dashd.1 dashd && chmod +x dashd"];
//
//                            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
//
//                            }];
//                        }
                    });
                }
            }];
        }
    }
    else {
        [self.versioningViewController addStringEvent:@"Error! There is some missing attributes. Please refresh and try again."];
    }
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
