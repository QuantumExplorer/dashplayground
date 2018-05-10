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

@implementation DPRepoModalController

MasternodesViewController *masternodeCon;

#pragma mark - Set Up

-(void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb
{
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    __block NSString * repositoryPath = [repository valueForKey:@"repository.url"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        NMSSHSession *ssh = [self sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:publicIP];
        
        if (!ssh.isAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO,@"SSH: error authenticating with server.");
            });
            return;
        }
        
        ssh.channel.requestPty = YES;
        
        NSError *error = nil;
        [ssh.channel execute:@"cd src" error:&error];
        if (error) {
            error = nil;
            [ssh.channel execute:@"mkdir src" error:&error];
            if(error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,[NSString stringWithFormat:@"SSH: error making src directory. %@", error.localizedDescription]);
                });
                return;
            }
        }
        
        //check if dash does exist then clone
        
        BOOL justCloned = FALSE;
        error = nil;
        [ssh.channel execute:@"cd src/dash" error:&error];
        if (error) {
            justCloned = TRUE;
            error = nil;
            
            [self sendDashGitCloneCommandForRepositoryPath:repositoryPath toDirectory:@"~/src/dash" onSSH:ssh error:error percentageClb:^(NSString *call, float percentage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"%@ %.2f",call,percentage);
                    [masternode setValue:@(percentage) forKey:@"operationPercentageDone"];
                });
            }];
        }
        
        
        //now let's make all this shit
        error = nil;
        [self sendDashCommandsList:@[@"./autogen.sh",@"./configure CPPFLAGS='-I/usr/local/BerkeleyDB.4.8/include -O2' LDFLAGS='-L/usr/local/BerkeleyDB.4.8/lib'",@"make",@"mkdir ~/.dashcore/",@"cp src/dashd ~/.dashcore/",@"cp src/dash-cli ~/.dashcore/",@"sudo cp src/dashd /usr/bin/dashd",@"sudo cp src/dash-cli /usr/bin/dash-cli"] onSSH:ssh onPath:@"cd src/dash;" error:error percentageClb:^(NSString *call, float percentage) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                NSLog(@"%@ %.2f",call,percentage);
//                [masternode setValue:@(percentage) forKey:@"operationPercentageDone"];
                NSString *string = [NSString stringWithFormat:@"Done %.2f % %",percentage];
                [masternodeCon addStringEventToMasternodeConsole:string];
            });
        }];
        
        [ssh disconnect];
        dispatch_async(dispatch_get_main_queue(), ^{
            [masternodeCon addStringEventToMasternodeConsole:[NSString stringWithFormat:@"SSH: disconnected from %@", publicIP]];
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [masternode setValue:repositoryPath forKey:@"repositoryUrl"];
            
            [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            [[DialogAlert sharedInstance] showAlertWithOkButton:@"Set up" message:@"Set up successfully!"];
        });

        //---------
    });
    
    
}

#pragma mark - Connectivity

//Toey

-(void)sendDashGitCloneCommandForRepositoryPath:(NSString*)repositoryPath toDirectory:(NSString*)directory onSSH:(NMSSHSession *)ssh error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    NSString *command = [NSString stringWithFormat:@"git clone %@ ~/src/dash",repositoryPath];
    dispatch_async(dispatch_get_main_queue(), ^{
        [masternodeCon addStringEventToMasternodeConsole:command];
    });
    [self sendExecuteCommand:command onSSH:ssh error:error];
    
}

-(void)sendDashCommandsList:(NSArray*)commands onSSH:(NMSSHSession*)ssh onPath:(NSString*)path error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    for (NSUInteger index = 0;index<[commands count];index++) {
        NSString * command = [commands objectAtIndex:index];
        
        [self sendExecuteCommand:[NSString stringWithFormat:@"%@ %@",path, command] onSSH:ssh error:error];
        
        int currentCommand = (int)index;
        currentCommand = currentCommand+1;
        
        clb(command,(currentCommand*100)/[commands count]);
    }
}

-(void)sendExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error {
    
    NSString *string = [NSString stringWithFormat:@"executing command %@", command];
    dispatch_async(dispatch_get_main_queue(), ^{
        [masternodeCon addStringEventToMasternodeConsole:string];
    });
    
    error = nil;
    [ssh.channel execute:command error:&error];
    if (error) {
        NSLog(@"SSH: error executing command %@ with reason %@", command, error);
        return;
    }
}

-(NMSSHSession*)sshInWithKeyPath:(NSString*)masternodeIP {
    if (![[DPMasternodeController sharedInstance] sshPath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"SSH_KEY.pem" exPath:@"~/Documents"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [[DPMasternodeController sharedInstance] setSshPath:pathString];
            return [self sshInWithKeyPath:pathString masternodeIp:masternodeIP];
        }
    }
    else{
        return [self sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:masternodeIP];
    }
    return nil;
}

-(NMSSHSession*)sshInWithKeyPath:(NSString*)keyPath masternodeIp:(NSString*)masternodeIp {
    NMSSHSession *session = [NMSSHSession connectToHost:masternodeIp withUsername:@"ubuntu"];
    
    if (session.isConnected) {
        [session authenticateByPublicKey:nil privateKey:keyPath andPassword:nil];
        
        if (session.isAuthorized) {
            NSLog(@"Authentication succeeded");
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternodeCon addStringEventToMasternodeConsole:@"SSH: authentication succeeded!"];
            });
        }
    }
    
    return session;
}

//End Toey

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
