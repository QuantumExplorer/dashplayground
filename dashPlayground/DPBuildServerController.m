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
                                                [tableArray addObject: tableDict];
                                                
                                                clb(YES, tableArray);
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
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
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
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
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
        
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
            
            if ([message rangeOfString:@"SSH:"].location == NSNotFound) {
                NSArray *messageArray = [message componentsSeparatedByString:@" "];
                if([messageArray count] == 10) {
                    __block NSMutableArray *dateList = [NSMutableArray array];
                    NSDictionary *dateDict = [NSMutableDictionary dictionary];
                    [dateDict setValue:[NSString stringWithFormat:@"%@ %@ %@",[messageArray objectAtIndex:7], [messageArray objectAtIndex:5], [messageArray objectAtIndex:8]] forKey:@"date"];
                    [dateDict setValue:[messageArray objectAtIndex:9] forKey:@"commitSha"];
                    [dateList addObject:dateDict];
                    clb(YES, dateList);
                }
            }
        }];
    }
}

- (void)getVersionsList:(NMSSHSession*)buildServerSession fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo fromBranch:(NSString*)branch storageType:(NSString*)type clb:(dashMutaArrayInfoClb)clb {
    
    NSString *command = [NSString stringWithFormat:@"cd /var/www/html/%@/%@-%@/%@ && ls -p | grep \"/\"", type, gitOwner, gitRepo, branch];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
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

- (void)comepileCheck:(NMSSHSession*)buildServerSession allObject:(NSArray*)allObjects {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
//        for(NSManagedObject *object in allObjects) {
//            [self compileCheck:buildServerSession withRepository:object reportConsole:NO];
//        }
//    });
    for(NSManagedObject *object in allObjects) {
        [self compileCheck:buildServerSession withRepository:object reportConsole:NO];
    }
}

- (void)compileCheck:(NMSSHSession*)buildServerSession withRepository:(NSManagedObject*)repoObject reportConsole:(BOOL)report {
    
    NSString *type = [repoObject valueForKey:@"type"];
    NSString *owner = [repoObject valueForKey:@"owner"];
    NSString *repoName = [repoObject valueForKey:@"repoName"];
    NSString *branch = [repoObject valueForKey:@"branch"];
    
    __block NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git fetch", type, owner, repoName, branch];
    
    NSError *error = nil;
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
        if(success == YES) {
            command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git status", type, owner, repoName, branch];
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
                if ([message rangeOfString:@"Your branch is up-to-date"].location != NSNotFound) {
                    if(report == YES) {
                        [self.buildServerViewController addStringEvent:message];
                    }
                    [repoObject setValue:@"up-to-date" forKey:@"status"];
                    
                    NSString *compileStatus = [self checkExistingOfDashdInRepo:buildServerSession type:type Owner:owner RepoName:repoName onBranch:branch];
                    [repoObject setValue:compileStatus forKey:@"compileStatus"];
                }
                else if ([message rangeOfString:@"Your branch is behind"].location != NSNotFound) {
                    if(report == YES) {
                        [self.buildServerViewController addStringEvent:message];
                    }
                    [repoObject setValue:@"out-of-date" forKey:@"status"];
                    [repoObject setValue:@"need to re-compile" forKey:@"compileStatus"];
                }
                else {
                    if ([message rangeOfString:@"could not read Username"].location != NSNotFound) {
                        [self.buildServerViewController addStringEvent:message];
                    }
                    else {
                        if(report == YES) {
                            [self.buildServerViewController addStringEvent:@"Error: could not get git information."];
                        }
                        [repoObject setValue:@"unknown" forKey:@"status"];
                    }
                }
            }];
            
            command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git rev-parse HEAD", type, owner, repoName, branch];
            
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
                if([message length] == 41) {
                    [repoObject setValue:[message substringToIndex:7] forKey:@"gitCommit"];
                }
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
                [repoObject setValue:@"unknown" forKey:@"status"];
            }
        }
        
    }];
}

- (NSString*)checkExistingOfDashdInRepo:(NMSSHSession*)buildServerSession type:(NSString*)type Owner:(NSString*)gitOwner RepoName:(NSString*)gitRepo onBranch:(NSString*)branch {
    
    __block NSString *compileStatus = @"";
    
    __block NSError *error = nil;
    __block NSString *command = [NSString stringWithFormat:@"ls ~/src/%@/%@-%@/%@/src/dashd", type, gitOwner, gitRepo, branch];
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        if ([message rangeOfString:@"No such file or directory"].location != NSNotFound) {
            compileStatus = @"need to compile";
        }
        else if ([message rangeOfString:[NSString stringWithFormat:@"/home/ubuntu/src/%@/%@-%@/%@/src/dashd\n", type, gitOwner, gitRepo, branch]].location != NSNotFound) {
            
            //then check dashcli
            command = [NSString stringWithFormat:@"ls ~/src/%@/%@-%@/%@/src/dash-cli", type, gitOwner, gitRepo, branch];
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
                if ([message rangeOfString:@"No such file or directory"].location != NSNotFound) {
                    compileStatus = @"need to compile";
                }
                else if ([message rangeOfString:[NSString stringWithFormat:@"/home/ubuntu/src/%@/%@-%@/%@/src/dash-cli\n", type, gitOwner, gitRepo, branch]].location != NSNotFound) {
                    compileStatus = @"finished";
                }
            }];
        }
    }];
    
    return compileStatus;
}

- (void)updateRepoCredential:(NMSSHSession*)buildServerSession repoObject:(NSManagedObject*)repoObject gitUsername:(NSString*)gitUsername gitPassword:(NSString*)gitPassword {
    NSString *type = [repoObject valueForKey:@"type"];
    NSString *owner = [repoObject valueForKey:@"owner"];
    NSString *repoName = [repoObject valueForKey:@"repoName"];
    NSString *branch = [repoObject valueForKey:@"branch"];
    
    NSError *error = nil;
    [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git config --global credential.helper cache", type, owner, repoName, branch] onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
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
            
            [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
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
                [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && ./autogen.sh", type, gitOwner, gitRepo, branch] onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buildServerViewController addStringEvent:message];
                    });
                    isSuccess = success;
                }];
                if(isSuccess == NO) return;
                
                [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && ./configure", type, gitOwner, gitRepo, branch] onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buildServerViewController addStringEvent:message];
                    });
                    isSuccess = success;
                }];
                if(isSuccess == NO) return;
                
                [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && make --file=Makefile -j10 -l15", type, gitOwner, gitRepo, branch] onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buildServerViewController addStringEvent:message];
                    });
                    isSuccess = success;
                }];
                
                if(isSuccess == YES) {//copy dashd and dash-cli to apache2
                    [self copyDashAppToApache:repoObject buildServerSession:buildServerSession];
                }
            });
        }
    }
    else if([repoStatus isEqualToString:@"out-of-date"]) {
        __block NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@ && git fetch && git pull && git rev-parse --short HEAD", type, gitOwner, gitRepo, branch];
        
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
            [self.buildServerViewController addStringEvent:message];
            [self compileCheck:buildServerSession withRepository:repoObject reportConsole:NO];
            
        }];
    }
}

- (void)copyDashAppToApache:(NSManagedObject*)repoObject buildServerSession:(NMSSHSession*)buildServerSession {
    NSString *gitOwner = [repoObject valueForKey:@"owner"];
    NSString *gitRepo = [repoObject valueForKey:@"repoName"];
    NSString *branch = [repoObject valueForKey:@"branch"];
    NSString *type = [repoObject valueForKey:@"type"];
    
    __block NSError *error = nil;
    __block NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/ && git rev-parse HEAD", type, gitOwner, gitRepo, branch];
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        if([message length] == 41) {
            command = [NSString stringWithFormat:@"sudo mkdir -p /var/www/html/%@/%@-%@/%@/%@ cd ~/src/%@/%@-%@/%@/src/ && sudo cp dashd /var/www/html/%@/%@-%@/%@/%@/", type, gitOwner, gitRepo, branch, message, type, gitOwner, gitRepo, branch, type, gitOwner, gitRepo, branch, message];
            [buildServerSession.channel execute:command error:&error];
            
            command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/src/ && sudo cp dash-cli /var/www/html/%@/%@-%@/%@/%@/", type, gitOwner, gitRepo, branch, type, gitOwner, gitRepo, branch, message];
            [buildServerSession.channel execute:command error:&error];
        }
    }];
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
