//
//  DPBuildServerController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 3/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DPBuildServerController.h"
#import "SshConnection.h"
#import "DialogAlert.h"
#import "GithubAPI.h"
#import "Repository+CoreDataClass.h"
#import "Branch+CoreDataClass.h"
#import "ProjectTypeTransformer.h"

#define BUILD_SERVER_IP @"[BUILD_SERVER_IP]"

@implementation DPBuildServerController

@synthesize buildServerViewController = _buildServerViewController;

-(NSString*)getBuildServerIP {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:BUILD_SERVER_IP];
}

-(void)setBuildServerIP:(NSString*)ipAddress {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:ipAddress forKey:BUILD_SERVER_IP];
}

- (void)getCompileData:(NMSSHSession*)buildServerSession dashClb:(dashMutaArrayInfoClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSArray *storageType = [NSArray arrayWithObjects:@"core", @"dapi", @"dashdrive", nil];
        
        for(NSString *type in storageType) {
            
            if([type isEqualToString:@"core"]) {
                [self getDirectory:type onPath:@"~/src" onSession:buildServerSession clb:^(BOOL success, NSArray *array) {
                    if(success == YES) {
                        if([array count] > 0) {
                            for(NSDictionary *dict in array) {
                                [self getBranchList:buildServerSession onPath:@"~/src" fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] storageType:type clb:^(BOOL success, NSMutableArray *object) {
                                    if(success == YES) {
                                        if([object count] > 0) {
                                            for(NSString *branch in object) {
                                                NSMutableArray *tableArray = [NSMutableArray array];
                                                NSDictionary *tableDict = [NSMutableDictionary dictionary];
                                                [tableDict setValue:[NSString stringWithFormat:@"%@-%@", [dict valueForKey:@"owner"], [dict valueForKey:@"repo"]] forKey:@"repoInfo"];
                                                [tableDict setValue:branch forKey:@"branch"];
                                                [tableDict setValue:type forKey:@"type"];
                                                [tableDict setValue:[dict valueForKey:@"owner"] forKey:@"owner"];
                                                [tableDict setValue:[dict valueForKey:@"repo"] forKey:@"repoName"];
                                                [self compileCheck:buildServerSession type:type owner:[dict valueForKey:@"owner"] repoName:[dict valueForKey:@"repo"] branch:branch dict:tableDict reportConsole:NO clb:^(BOOL success, NSDictionary *dictionary) {
                                                    if(success == YES) {
                                                        [tableArray addObject: dictionary];
                                                        clb(YES, tableArray);
                                                    }
                                                }];
                                            }
                                        }
                                    }
                                }];
                            }
                        }
                    }
                }];
            }
        }
    });
}

- (void)getAllRepository:(NMSSHSession*)buildServerSession dashClb:(dashMutaArrayInfoClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSArray *storageType = [NSArray arrayWithObjects:@"core", @"dapi", @"dashdrive", nil];
        
        for(NSString *type in storageType) {
            if([type isEqualToString:@"core"]) {
                
                [self getDirectory:type onPath:@"/var/www/html" onSession:buildServerSession clb:^(BOOL success, NSArray *array) {
                    if(success == YES) {
                        __block NSMutableArray *commitList = [NSMutableArray array];
                        __block NSMutableArray *dateList;
                        if([array count] > 0) {
                            for(NSDictionary *dict in array) {
                                [self getBranchList:buildServerSession onPath:@"/var/www/html" fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] storageType:type clb:^(BOOL success, NSMutableArray *object) {
                                    if(success == YES) {
                                        if([object count] > 0) {
                                            for(NSString *branch in object) {
                                                [self getVersionsList:buildServerSession fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] fromBranch:branch storageType:type clb:^(BOOL success, NSMutableArray *object) {
                                                    if(success == YES) {
                                                        commitList = object;
                                                        
                                                        [self getCreatedDirectoryDate:buildServerSession fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] fromBranch:branch storageType:type commitList:commitList clb:^(BOOL success, NSMutableArray *object) {
                                                            if(success == YES) {
                                                                dateList = object;
                                                                
                                                                NSMutableArray *tableArray = [NSMutableArray array];
                                                                NSDictionary *tableDict = [NSMutableDictionary dictionary];
                                                                [tableDict setValue:[dict valueForKey:@"owner"] forKey:@"owner"];
                                                                [tableDict setValue:[dict valueForKey:@"repo"] forKey:@"repo"];
                                                                [tableDict setValue:branch forKey:@"branch"];
                                                                [tableDict setValue:dateList forKey:@"commitInfo"];
                                                                [tableDict setValue:type forKey:@"type"];
                                                                [tableArray addObject: tableDict];
                                                                clb(YES, tableArray);
                                                            }
                                                        }];
                                                    }
                                                }];
                                            }
                                        }
                                    }
                                }];
                            }
                        }
                    }
                }];
            }
            else if([type isEqualToString:@"dapi"]) {
                
            }
            else {
                
            }
        }
    });
}

- (void)getDirectory:(NSString*)type onPath:(NSString*)path onSession:(NMSSHSession*)buildServerSession clb:(dashArrayClb)clb  {
    
    NSString *command = [NSString stringWithFormat:@"cd %@/%@ && ls -p | grep \"/\"", path, type];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
        
        if ([message rangeOfString:@"SSH"].location == NSNotFound) {
            NSArray *directory = [message componentsSeparatedByString:@"\n"];
            
            if([directory count] > 0) {
                __block NSArray *ownerAndRepoNameArray = [NSArray array];
                ownerAndRepoNameArray = [self getOwnerAndRepoName:directory];
                clb(YES, ownerAndRepoNameArray);
            }
        }
        
    }];
}

- (void)getBranchList:(NMSSHSession*)buildServerSession onPath:(NSString*)path fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo storageType:(NSString*)type clb:(dashMutaArrayInfoClb)clb {
    
    NSString *command = [NSString stringWithFormat:@"cd %@/%@/%@-%@/ && ls -p | grep \"/\"", path, type, gitOwner, gitRepo];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
        
        if ([message rangeOfString:@"SSH"].location == NSNotFound) {
            NSArray *branchArray = [message componentsSeparatedByString:@"\n"];
            for(NSString *branch in branchArray) {
                if([branch length] > 0) {
                    __block NSMutableArray *branchList = [NSMutableArray array];
                    NSString *branchName = [branch substringToIndex:[branch length] -1];
                    [branchList addObject:branchName];
                    clb(YES, branchList);
                }
            }
        }
        
    }];
}

- (void)getCreatedDirectoryDate:(NMSSHSession*)buildServerSession fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo fromBranch:(NSString*)branch storageType:(NSString*)type commitList:(NSArray*)commitList clb:(dashMutaArrayInfoClb)clb {
    
    for(NSDictionary* commit in commitList) {
        NSString *command = [NSString stringWithFormat:@"cd /var/www/html/%@/%@-%@/%@ && ls -ldc %@", type, gitOwner, gitRepo, branch, [commit valueForKey:@"commitSha"]];
        NSError *error = nil;
        
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error  mainThread:NO dashClb:^(BOOL success, NSString *message) {
            
            if ([message rangeOfString:@"SSH:"].location == NSNotFound) {
                NSArray *messageArray = [message componentsSeparatedByString:@" "];
                int hashIndex = 0, dateIndex = 0, monthIndex = 0;
                if([messageArray count] == 9) {
                    dateIndex = 5;
                    hashIndex = 8;
                }
                else {
                    dateIndex = 6;
                    hashIndex = 9;
                }
                if([messageArray count] >= 9) {
                    __block NSMutableArray *dateList = [NSMutableArray array];
                    NSDictionary *buildDict = [NSMutableDictionary dictionary];
                    
                    if(dateIndex == 6) {
                        if([[messageArray objectAtIndex:dateIndex] isEqualToString:@""]) {
                            monthIndex = 5;
                        }
                        else monthIndex = dateIndex;
                    }
                    else if(dateIndex == 5) {
                        if([[messageArray objectAtIndex:dateIndex] isEqualToString:@""]) {
                            monthIndex = 4;
                        }
                        else monthIndex = dateIndex;
                    }
                    
                    [buildDict setValue:[NSString stringWithFormat:@"%@ %@ %@",[messageArray objectAtIndex:dateIndex+1], [messageArray objectAtIndex:monthIndex], [messageArray objectAtIndex:dateIndex+2]] forKey:@"date"];
                    [buildDict setValue:[messageArray objectAtIndex:hashIndex] forKey:@"commitSha"];
                    
                    NSString *commitSha = [[messageArray objectAtIndex:hashIndex] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                    NSDictionary *commitDict = [[GithubAPI sharedInstance] getSingleCommitDictionaryData:gitOwner repository:gitRepo commit:commitSha];
                    
                    NSString *commitMsg = [NSString stringWithFormat:@"%@", [[commitDict valueForKey:@"commit"] valueForKey:@"message"]];
                    if([[[commitDict valueForKey:@"commit"] valueForKey:@"message"] length] > 20) {
                        long halfStr = [[[commitDict valueForKey:@"commit"] valueForKey:@"message"] length]/2;
                        commitMsg = [NSString stringWithFormat:@"%@...", [[[commitDict valueForKey:@"commit"] valueForKey:@"message"] substringToIndex:halfStr]];
                    }
                    [buildDict setValue:commitMsg forKey:@"message"];
                    
                    [dateList addObject:buildDict];
                    clb(YES, dateList);
                }
            }
        }];
    }
}

- (void)getVersionsList:(NMSSHSession*)buildServerSession fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo fromBranch:(NSString*)branch storageType:(NSString*)type clb:(dashMutaArrayInfoClb)clb {
    
    NSString *command = [NSString stringWithFormat:@"cd /var/www/html/%@/%@-%@/%@ && ls -p | grep \"/\"", type, gitOwner, gitRepo, branch];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
        
        if ([message rangeOfString:@"SSH:"].location == NSNotFound) {
            NSArray *commitArray = [message componentsSeparatedByString:@"\n"];
            for(NSString *commitHash in commitArray) {
                if([commitHash length] > 0) {
                    __block NSMutableArray *commitList = [NSMutableArray array];
                    NSString *newCommitHash = [commitHash substringToIndex:[commitHash length] -1];
                    NSDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setValue:branch forKey:@"branch"];
                    [dict setValue:newCommitHash forKey:@"commitSha"];
                    [commitList addObject:dict];
                    clb(YES, commitList);
                }
            }
        }
        
    }];
}

- (NSArray*)getOwnerAndRepoName:(NSArray*)directory {
    NSMutableArray *ownerAndRepoArray = [NSMutableArray array];
    
    for(NSString* dir in directory) {
        NSArray *dirArray = [dir componentsSeparatedByString:@"-"];
        
        if([dirArray count] == 2) {
            NSDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:[dirArray objectAtIndex:0] forKey:@"owner"];
            [dict setValue:[[dirArray objectAtIndex:1] substringToIndex:[[dirArray objectAtIndex:1] length] -1] forKey:@"repo"];
            
            [ownerAndRepoArray addObject:dict];
        }
    }
    
    return ownerAndRepoArray;
}

- (void)compileCheck:(NMSSHSession*)buildServerSession type:(NSString*)type owner:(NSString*)owner repoName:(NSString*)repoName branch:(NSString*)branch dict:(NSDictionary*)dict reportConsole:(BOOL)report clb:(dashDictInfoClb)clb {
    
    __block NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git fetch", type, owner, repoName, branch];
    
    NSError *error = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
            
            if(success == YES) {
                command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git status", type, owner, repoName, branch];
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
                    if ([message rangeOfString:@"Your branch is up-to-date"].location != NSNotFound) {
                        if(report == YES) {
                            [self.buildServerViewController addStringEvent:message];
                        }
                        [dict setValue:@"up-to-date" forKey:@"status"];
                        
                        [self checkExistingOfDashdInRepo:buildServerSession type:type Owner:owner RepoName:repoName onBranch:branch clb:^(BOOL success, NSString *message) {
                            if(success == YES) {
                                [dict setValue:message forKey:@"compileStatus"];
                            }
                        }];
                    }
                    else if ([message rangeOfString:@"Your branch is behind"].location != NSNotFound) {
                        if(report == YES) {
                            [self.buildServerViewController addStringEvent:message];
                        }
                        [dict setValue:@"out-of-date" forKey:@"status"];
                        [dict setValue:@"need to re-compile" forKey:@"compileStatus"];
                    }
                    else {
                        if ([message rangeOfString:@"could not read Username"].location != NSNotFound) {
                            [self.buildServerViewController addStringEvent:message];
                        }
                        else {
                            if(report == YES) {
                                [self.buildServerViewController addStringEvent:@"Error: could not get git information."];
                            }
                            [dict setValue:@"unknown" forKey:@"status"];
                        }
                    }
                }];
                
                command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git rev-parse HEAD", type, owner, repoName, branch];
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    if([message length] == 41) {
                        [dict setValue:[message substringToIndex:7] forKey:@"gitCommit"];
                    }
                    clb(YES,dict);
                }];
            }
            else {
                if ([message rangeOfString:@"could not read Username"].location != NSNotFound) {
                    [self.buildServerViewController addStringEvent:message];
                }
                else {
                    if(report == YES) {
                        [self.buildServerViewController addStringEvent:@"Error: could not get git information."];
                    }
                    [dict setValue:@"unknown" forKey:@"status"];
                    clb(YES,dict);
                }
            }
            
        }];
    });
}

- (void)checkExistingOfDashdInRepo:(NMSSHSession*)buildServerSession type:(NSString*)type Owner:(NSString*)gitOwner RepoName:(NSString*)gitRepo onBranch:(NSString*)branch clb:(dashClb)clb {
    
    __block NSString *compileStatus = @"";
    
    __block NSError *error = nil;
    __block NSString *command = [NSString stringWithFormat:@"ls ~/src/%@/%@-%@/%@/src/dashd", type, gitOwner, gitRepo, branch];
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
        if ([message rangeOfString:@"No such file or directory"].location != NSNotFound) {
            compileStatus = @"need to compile";
            clb(YES, compileStatus);
        }
        else if ([message rangeOfString:[NSString stringWithFormat:@"/home/ubuntu/src/%@/%@-%@/%@/src/dashd\n", type, gitOwner, gitRepo, branch]].location != NSNotFound) {
            
            //then check dashcli
            command = [NSString stringWithFormat:@"ls ~/src/%@/%@-%@/%@/src/dash-cli", type, gitOwner, gitRepo, branch];
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
                if ([message rangeOfString:@"No such file or directory"].location != NSNotFound) {
                    compileStatus = @"need to compile";
                    clb(YES, compileStatus);
                }
                else if ([message rangeOfString:[NSString stringWithFormat:@"/home/ubuntu/src/%@/%@-%@/%@/src/dash-cli\n", type, gitOwner, gitRepo, branch]].location != NSNotFound) {
                    compileStatus = @"finished";
                    clb(YES, compileStatus);
                }
            }];
        }
    }];
}

- (void)updateRepositoryCredentials:(NMSSHSession*)buildServerSession forBranch:(Branch*)branch gitUsername:(NSString*)gitUsername gitPassword:(NSString*)gitPassword {
    Repository * repository = branch.repository;
    NSString *projectDirectory = [ProjectTypeTransformer directoryForProject:branch.repository.project];

    
    NSError *error = nil;
    [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git config --global credential.helper cache", projectDirectory, repository.owner, repository.name, branch.name] onSSH:buildServerSession error:error  mainThread:YES dashClb:^(BOOL success, NSString *message) {
        
    }];
}

- (void)cloneRepository:(NMSSHSession*)buildServerSession withGitLink:(NSString*)gitlink withBranch:(NSString*)branch type:(NSString*)type {
    NSArray *gitlinkArray = [gitlink componentsSeparatedByString:@"/"];
    
    if([gitlinkArray count] == 5 && [branch length] > 0) {
        NSString *gitOwner = [gitlinkArray objectAtIndex:3];
        
        NSArray *gitRepoArray = [[gitlinkArray objectAtIndex:4] componentsSeparatedByString:@"."];
        if([gitRepoArray count] == 2) {
            NSString *gitRepo = [gitRepoArray objectAtIndex:0];
            
            __block NSError *error = nil;
            
            __block NSString *command = [NSString stringWithFormat:@"git clone -b %@ %@ ~/src/%@/%@-%@/%@", branch, gitlink, type, gitOwner, gitRepo, branch];
            
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                if ([message rangeOfString:@"already exists and is not an empty directory"].location != NSNotFound) {
                    [self.buildServerViewController addStringEvent:@"This repository already exists."];
                }
                else if([message length] == 0) {
                    [self.buildServerViewController addStringEvent:@"Clone successfully!"];
                }
                else if ([message rangeOfString:@"could not read Username"].location != NSNotFound) {
                    NSString *gitUsername = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github" message:@"Please enter your github username." placeHolder:@"(ex. user01)"];
                    NSString *gitPassword = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github" message:@"Please enter your github password."];
                    
                    if(gitUsername != nil || gitPassword != nil) {
                        [self cloneRepository:buildServerSession withGitLink:[NSString stringWithFormat:@"https://%@:%@@github.com/%@/%@.git", gitUsername, gitPassword, gitOwner, gitRepo] withBranch:branch type:type];
                        
                        [buildServerSession.channel execute:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git config --global user.name \"%@\" && git config --global user.password \"%@\" && git config credential.helper store", type, gitOwner, gitRepo, branch, gitUsername, gitPassword] error:&error];
                    }
                }
                else {
                    [self.buildServerViewController addStringEvent:message];
                }
            }];
            
            
        }
        else {
            [self.buildServerViewController addStringEvent:@"Error: this repository doesn't seem to be exist."];
        }
    }
    else {
        [self.buildServerViewController addStringEvent:@"Error: this repository doesn't seem to be exist."];
    }
}

- (void)updateRepository:(NSManagedObject*)repoObject buildServerSession:(NMSSHSession*)buildServerSession {
    NSString *gitOwner = [repoObject valueForKey:@"owner"];
    NSString *gitRepo = [repoObject valueForKey:@"repoName"];
    NSString *branch = [repoObject valueForKey:@"branch"];
    NSString *type = [repoObject valueForKey:@"type"];
    NSString *repoStatus = [repoObject valueForKey:@"status"];
    NSError *error = nil;
    
    
    if([repoStatus isEqualToString:@"up-to-date"]) {
        
        NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Warning" message:@"Are you sure you want to re compile this repository?"];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
            //now let's make all this shit
            
            [self.buildServerViewController addStringEvent:@"This will take around 30 mins. Please do not close the program!"];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                
                __block BOOL isSuccess = YES;
                [self.buildServerViewController addStringEvent:@"Executing ./autogen.sh"];
                [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && ./autogen.sh", type, gitOwner, gitRepo, branch] onSSH:buildServerSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    [self.buildServerViewController addStringEvent:message];
                    isSuccess = success;
                }];
                if(isSuccess == NO) return;
                
                [self.buildServerViewController addStringEvent:@"Executing ./configure"];
                [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && ./configure", type, gitOwner, gitRepo, branch] onSSH:buildServerSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    [self.buildServerViewController addStringEvent:message];
                    isSuccess = success;
                }];
                if(isSuccess == NO) return;
                
                [self.buildServerViewController addStringEvent:@"Executing make --file=Makefile -j4 -l8"];
                [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && make --file=Makefile -j4 -l8", type, gitOwner, gitRepo, branch] onSSH:buildServerSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    [self.buildServerViewController addStringEvent:message];
                    isSuccess = success;
                }];
                
                if(isSuccess == YES) {//copy dashd and dash-cli to apache2
                    [self copyDashAppToApache:repoObject buildServerSession:buildServerSession];
                }
            });
        }
    }
    else if([repoStatus isEqualToString:@"out-of-date"]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            __block NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@ && git fetch && git pull && git rev-parse --short HEAD", type, gitOwner, gitRepo, branch];
            
            [self.buildServerViewController addStringEvent:command];
            
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:YES dashClb:^(BOOL success, NSString *message) {
                [self.buildServerViewController addStringEvent:message];
                //            [self compileCheck:buildServerSession withRepository:repoObject reportConsole:NO];
                
            }];
        });
    }
}

- (void)copyDashAppToApache:(NSManagedObject*)repoObject buildServerSession:(NMSSHSession*)buildServerSession {
    NSString *gitOwner = [repoObject valueForKey:@"owner"];
    NSString *gitRepo = [repoObject valueForKey:@"repoName"];
    NSString *branch = [repoObject valueForKey:@"branch"];
    NSString *type = [repoObject valueForKey:@"type"];
    
    __block NSError *error = nil;
    __block NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git rev-parse HEAD", type, gitOwner, gitRepo, branch];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        [self.buildServerViewController addStringEvent:@"Moving dash-cli and dashd to download directory..."];
    
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
            if([message length] == 41) {
                command = [NSString stringWithFormat:@"sudo mkdir -p /var/www/html/%@/%@-%@/%@/%@ cd ~/src/%@/%@-%@/%@/src/ && sudo cp dashd /var/www/html/%@/%@-%@/%@/%@/", type, gitOwner, gitRepo, branch, message, type, gitOwner, gitRepo, branch, type, gitOwner, gitRepo, branch, message];
                [buildServerSession.channel execute:command error:&error];
                
                command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/src/ && sudo cp dash-cli /var/www/html/%@/%@-%@/%@/%@/", type, gitOwner, gitRepo, branch, type, gitOwner, gitRepo, branch, message];
                [buildServerSession.channel execute:command error:&error];
                
                [repoObject setValue:@"finished" forKey:@"compileStatus"];
                [self.buildServerViewController addStringEvent:@"Finished compiling."];
            }
        }];
    });
}

#pragma mark - Singleton methods

+ (DPBuildServerController *)sharedInstance
{
    static DPBuildServerController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPBuildServerController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
