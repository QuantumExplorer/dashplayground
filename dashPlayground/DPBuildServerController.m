//
//  DPBuildServerController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 3/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DPBuildServerController.h"
#import "SshConnection.h"

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

- (NSMutableArray*)getCompileData:(NMSSHSession*)buildServerSession {
    NSArray *storageType = [NSArray arrayWithObjects:@"core", @"dapi", @"dashdrive", nil];
    
    NSMutableArray *tableArray = [NSMutableArray array];
    
    for(NSString *type in storageType) {
        
        if([type isEqualToString:@"core"]) {
            NSArray *ownerAndRepoNameArray = [self getDirectory:type onPath:@"~/src" onSession:buildServerSession];
            NSMutableArray *branchList;
            if([ownerAndRepoNameArray count] > 0) {
                for(NSDictionary *dict in ownerAndRepoNameArray) {
                    branchList = [self getBranchList:buildServerSession onPath:@"~/src" fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] storageType:type];
                    
                    if([branchList count] > 0) {
                        for(NSString *branch in branchList) {
                            NSDictionary *tableDict = [NSMutableDictionary dictionary];
                            [tableDict setValue:[NSString stringWithFormat:@"%@-%@", [dict valueForKey:@"owner"], [dict valueForKey:@"repo"]] forKey:@"repoInfo"];
                            [tableDict setValue:branch forKey:@"branch"];
                            [tableDict setValue:type forKey:@"type"];
                            [tableDict setValue:[dict valueForKey:@"owner"] forKey:@"owner"];
                            [tableDict setValue:[dict valueForKey:@"repo"] forKey:@"repoName"];
                            [tableArray addObject: tableDict];
                        }
                    }
                }
            }
        }
    }
    
    return tableArray;
}

- (NSMutableArray*)getAllRepository:(NMSSHSession*)buildServerSession {
    NSArray *storageType = [NSArray arrayWithObjects:@"core", @"dapi", @"dashdrive", nil];
    
    NSMutableArray *tableArray = [NSMutableArray array];
    
    for(NSString *type in storageType) {
        
        if([type isEqualToString:@"core"]) {
            
            NSArray *ownerAndRepoNameArray = [self getDirectory:type onPath:@"/var/www/html" onSession:buildServerSession];
            NSMutableArray *branchList;
            NSMutableArray *commitList = [NSMutableArray array];
            NSMutableArray *dateList;
            if([ownerAndRepoNameArray count] > 0) {
                for(NSDictionary *dict in ownerAndRepoNameArray) {
                    branchList = [self getBranchList:buildServerSession onPath:@"/var/www/html" fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] storageType:type];
                    if([branchList count] > 0) {
                        for(NSString *branch in branchList) {
                            commitList = [self getCommitList:buildServerSession fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] fromBranch:branch storageType:type];
                            dateList = [self getCreatedDirectoryDate:buildServerSession fromOwner:[dict valueForKey:@"owner"] fromRepo:[dict valueForKey:@"repo"] fromBranch:branch storageType:type commitList:commitList];
                            
                            NSDictionary *tableDict = [NSMutableDictionary dictionary];
                            [tableDict setValue:[dict valueForKey:@"owner"] forKey:@"owner"];
                            [tableDict setValue:[dict valueForKey:@"repo"] forKey:@"repo"];
                            [tableDict setValue:branch forKey:@"branch"];
                            [tableDict setValue:dateList forKey:@"commitInfo"];
                            [tableDict setValue:type forKey:@"type"];
                            [tableArray addObject: tableDict];
                        }
                    }
                }
            }
        }
        else if([type isEqualToString:@"dapi"]) {
            
        }
        else {
            
        }
    }
    
    return tableArray;
}

- (NSArray *)getDirectory:(NSString*)type onPath:(NSString*)path onSession:(NMSSHSession*)buildServerSession  {
    
    __block NSArray *ownerAndRepoNameArray = [NSArray array];
    
    NSString *command = [NSString stringWithFormat:@"cd %@/%@ && ls -p | grep \"/\"", path, type];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
        if ([message rangeOfString:@"SSH"].location == NSNotFound) {
            NSArray *directory = [message componentsSeparatedByString:@"\n"];
            
            if([directory count] > 0) {
                ownerAndRepoNameArray = [self getOwnerAndRepoName:directory];
            }
        }
        
    }];
    
    return ownerAndRepoNameArray;
}

- (NSMutableArray*)getBranchList:(NMSSHSession*)buildServerSession onPath:(NSString*)path fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo storageType:(NSString*)type {
    
    __block NSMutableArray *branchList = [NSMutableArray array];
    
    NSString *command = [NSString stringWithFormat:@"cd %@/%@/%@-%@/ && ls -p | grep \"/\"", path, type, gitOwner, gitRepo];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
        if ([message rangeOfString:@"SSH"].location == NSNotFound) {
            NSArray *branchArray = [message componentsSeparatedByString:@"\n"];
            for(NSString *branch in branchArray) {
                if([branch length] > 0) {
                    NSString *branchName = [branch substringToIndex:[branch length] -1];
                    [branchList addObject:branchName];
                }
            }
        }
        
    }];
    
    return branchList;
}

- (NSMutableArray*)getCreatedDirectoryDate:(NMSSHSession*)buildServerSession fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo fromBranch:(NSString*)branch storageType:(NSString*)type commitList:(NSArray*)commitList {
    __block NSMutableArray *dateList = [NSMutableArray array];
    
    for(NSDictionary* commit in commitList) {
        NSString *command = [NSString stringWithFormat:@"cd /var/www/html/%@/%@-%@/%@ && ls -ldc %@", type, gitOwner, gitRepo, branch, [commit valueForKey:@"commitSha"]];
        NSError *error = nil;
        
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
            
            if ([message rangeOfString:@"SSH:"].location == NSNotFound) {
                NSArray *messageArray = [message componentsSeparatedByString:@" "];
                if([messageArray count] == 10) {
                    NSDictionary *dateDict = [NSMutableDictionary dictionary];
                    [dateDict setValue:[NSString stringWithFormat:@"%@ %@ %@",[messageArray objectAtIndex:7], [messageArray objectAtIndex:5], [messageArray objectAtIndex:8]] forKey:@"date"];
                    [dateDict setValue:[messageArray objectAtIndex:9] forKey:@"commitSha"];
                    [dateList addObject:dateDict];
                }
            }
        }];
    }
    
    
    return dateList;
}

- (NSMutableArray*)getCommitList:(NMSSHSession*)buildServerSession fromOwner:(NSString*)gitOwner fromRepo:(NSString*)gitRepo fromBranch:(NSString*)branch storageType:(NSString*)type {
    
    __block NSMutableArray *commitList = [NSMutableArray array];
    
    NSString *command = [NSString stringWithFormat:@"cd /var/www/html/%@/%@-%@/%@ && ls -p | grep \"/\"", type, gitOwner, gitRepo, branch];
    
    NSError *error = nil;
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        
        if ([message rangeOfString:@"SSH:"].location == NSNotFound) {
            NSArray *commitArray = [message componentsSeparatedByString:@"\n"];
            for(NSString *commitHash in commitArray) {
                if([commitHash length] > 0) {
                    NSString *newCommitHash = [commitHash substringToIndex:[commitHash length] -1];
                    NSDictionary *dict = [NSMutableDictionary dictionary];
                    [dict setValue:branch forKey:@"branch"];
                    [dict setValue:newCommitHash forKey:@"commitSha"];
                    [commitList addObject:dict];
                }
            }
        }
        
    }];
    
    return commitList;
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

- (void)compileCheck:(NMSSHSession*)buildServerSession withRepository:(NSManagedObject*)repoObject {
    
    NSString *type = [repoObject valueForKey:@"type"];
    NSString *owner = [repoObject valueForKey:@"owner"];
    NSString *repoName = [repoObject valueForKey:@"repoName"];
    NSString *branch = [repoObject valueForKey:@"branch"];
    
    NSString *command = [NSString stringWithFormat:@"cd ~/src/%@/%@-%@/%@/%@/ && git status -uno", type, owner, repoName, branch, repoName];
    
    NSError *error = nil;
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:buildServerSession error:error dashClb:^(BOOL success, NSString *message) {
        NSLog(@"%@", message);
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
