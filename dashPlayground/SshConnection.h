//
//  SshConnection.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 23/5/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "InstanceStateTransformer.h"
#import "DPLocalNodeController.h"
#import <NMSSH/NMSSH.h>

typedef void (^dashPercentageClb)(NSString * call,float percentage);

@interface SshConnection : NSObject

+(SshConnection*)sharedInstance;

-(void)sshInWithKeyPath:(NSString*)keyPath masternodeIp:(NSString*)masternodeIp openShell:(BOOL)shell clb:(dashSshClb)clb;
-(void)sendDashGitCloneCommandForRepositoryPath:(NSString*)repositoryPath toDirectory:(NSString*)directory onSSH:(NMSSHSession *)ssh  onBranch:(NSString*)branchName error:(NSError*)error dashClb:(dashClb)clb;
-(void)sendDashCommandsList:(NSArray*)commands onSSH:(NMSSHSession*)ssh onPath:(NSString*)path error:(NSError*)error dashClb:(dashClb)clb;
-(void)sendWriteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error percentageClb:(dashPercentageClb)clb;
-(void)sendExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error mainThread:(BOOL)mainThread dashClb:(dashClb)clb;

@end
