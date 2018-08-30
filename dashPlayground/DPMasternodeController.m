//
//  DPMasternodeController.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DPMasternodeController.h"
#import "Defines.h"
#import "AppDelegate.h"
#import "NSArray+SWAdditions.h"
#import "DPDataStore.h"
#import "CkoSFtp.h"
#import "CkoSsh.h"
#import "CkoSshKey.h"
#import "CkoStringBuilder.h"
#import "DPLocalNodeController.h"
#import "MasternodeStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"
//#import "DFSSHServer.h"
//#import "DFSSHConnector.h"
//#import "DFSSHOperator.h"
#import "DialogAlert.h"
#import "PreferenceData.h"
#import <NMSSH/NMSSH.h>
#import "SshConnection.h"
#import "SentinelStateTransformer.h"
#import "DPChainSelectionController.h"

#define MASTERNODE_PRIVATE_KEY_STRING @"[MASTERNODE_PRIVATE_KEY]"
#define RPC_PASSWORD_STRING @"[RPC_PASSWORD]"
#define EXTERNAL_IP_STRING @"[EXTERNAL_IP]"

#define SSHPATH @"sshPath"
#define SSH_NAME_STRING @"SSH_NAME"

@interface DPMasternodeController ()

@end

@implementation DPMasternodeController

@synthesize masternodeViewController = _masternodeViewController;

-(NSString*)sshPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:SSHPATH];
}

-(void)setSshPath:(NSString*)sshPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:sshPath forKey:SSHPATH];
}

-(NSString*)getSshName {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:SSH_NAME_STRING];
}

-(void)setSshName:(NSString*)sshName {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:sshName forKey:SSH_NAME_STRING];
}

#pragma mark - Connectivity

//Toey

-(void)sendDashCommandsList:(NSArray*)commands onSSH:(NMSSHSession*)ssh onPath:(NSString*)path error:(NSError*)error percentageClb:(dashPercentageClb)clb {
    
    for (NSUInteger index = 0;index<[commands count];index++) {
        NSString * command = [commands objectAtIndex:index];
        
//        NSLog(@"Executing command %@", command);
        
        [self sendExecuteCommand:[NSString stringWithFormat:@"%@ %@",path, command] onSSH:ssh error:error];
        
        int currentCommand = (int)index;
        currentCommand = currentCommand+1;
        
        clb(command,(currentCommand*100)/[commands count]);
    }
}

-(void)sendExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error {
    error = nil;
    [ssh.channel execute:command error:&error];
    if (error) {
        NSLog(@"SSH: error executing command %@ - %@", command, error);
        return;
    }
}

-(NSString*)getResponseExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error {
    error = nil;
    NSString *response = [ssh.channel execute:command error:&error];
    if (error) {
        NSLog(@"SSH: error executing command %@ - %@", command, error);
        return [NSString stringWithFormat:@"%@", [error localizedDescription]];
    }
    return response;
}

//-(NSString*)sendGitCommand:(NSString*)command onSSH:(CkoSsh *)ssh {
//    return [[self sendGitCommands:@[command] onSSH:ssh] valueForKey:command];
//}

-(NSDictionary*)sendGitCommands:(NSArray*)commands onSSH:(NMSSHSession *)ssh onPath:(NSString*)gitPath {
    
    NSError *error = nil;
    [ssh.channel execute:[NSString stringWithFormat:@"cd ~%@", gitPath] error:&error];
    if (error) {
        NSLog(@"location not found! %@",error.localizedDescription);
        return nil;
    }
    
    NSMutableDictionary * rDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
    for (NSString * gitCommand in commands) {
        //   Run the 2nd command in the remote shell, which will be
        //   to "ls" the directory.
        error = nil;
        NSString *cmdOutput = [ssh.channel execute:[NSString stringWithFormat:@"cd ~%@; git %@", gitPath, gitCommand] error:&error];
        if (error) {
            NSLog(@"error trying to send git command! %@",error.localizedDescription);
            return nil;
        }
        else{
            NSArray * components = [cmdOutput componentsSeparatedByString:@"\r\n"];
            if ([components count] >= 2) {
                //                if ([[NSString stringWithFormat:@"git %@",gitCommand] isEqualToString:components[0]]) {
                //                    [rDict setObject:components[1] forKey:gitCommand];
                //                }
                for (id eachComponent in components) {
                    if(![eachComponent isEqualToString:@""])
                    {
                        if([gitCommand isEqualToString:@"remote -v"]) {
                            [rDict setObject:components[0] forKey:gitCommand];//set only (fetch) branch
                            break;
                        }
                        [rDict setObject:eachComponent forKey:gitCommand];
                    }
                }
            }
            else {
                [rDict setObject:cmdOutput forKey:gitCommand];
            }
        }
    }
    
    return rDict;
}

-(NMSSHSession*)connectInstance:(NSManagedObject*)masternode {
    __block NMSSHSession *ssh;
    [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        ssh = sshSession;
    }];
    
    return ssh;
}

//End Toey


//-(NSString*)sendGitCommand:(NSString*)command onSSH:(CkoSsh *)ssh {
//    return [[self sendGitCommands:@[command] onSSH:ssh] valueForKey:command];
//}
//
//-(NSDictionary*)sendGitCommands:(NSArray*)commands onSSH:(CkoSsh *)ssh {
//
//    NSInteger channelNum = [[ssh QuickShell] integerValue];
//    if (channelNum < 0) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return nil;
//    }
//
//    //  This is the prompt we'll be expecting to find in
//    //  the output of the remote shell.
//    NSString *myPrompt = @":~/src/dash$";
//    //   Run the 1st command in the remote shell, which will be to
//    //   "cd" to a subdirectory.
//    BOOL success = [ssh ChannelSendString: @(channelNum) strData: @"cd src/dash/\n" charset: @"ansi"];
//    if (success != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return nil;
//    }
//
//    //    NSNumber * v = [ssh ChannelReadAndPoll:@(channelNum) pollTimeoutMs:@(5000)];
//    //
//    //    NSString *cmdOutpu2t = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
//    //    if (ssh.LastMethodSuccess != YES) {
//    //        NSLog(@"%@",ssh.LastErrorText);
//    //        return nil;
//    //    };
//    //  Retrieve the output.
//    success = [ssh ChannelReceiveUntilMatch: @(channelNum) matchPattern: myPrompt charset: @"ansi" caseSensitive: YES];
//    if (success != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return nil;
//    }
//
//    //   Display what we've received so far.  This clears
//    //   the internal receive buffer, which is important.
//    //   After we send the command, we'll be reading until
//    //   the next command prompt.  If the command prompt
//    //   is already in the internal receive buffer, it'll think it's
//    //   already finished...
//    NSString *cmdOutput = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
//    if (ssh.LastMethodSuccess != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return nil;
//    };
//    NSMutableDictionary * rDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
//    for (NSString * gitCommand in commands) {
//        //   Run the 2nd command in the remote shell, which will be
//        //   to "ls" the directory.
//        success = [ssh ChannelSendString: @(channelNum) strData:[NSString stringWithFormat:@"git %@\n",gitCommand] charset: @"ansi"];
//        if (success != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            return nil;
//        }
//
//        //  Retrieve and display the output.
//        success = [ssh ChannelReceiveUntilMatch: @(channelNum) matchPattern: myPrompt charset: @"ansi" caseSensitive: YES];
//        if (success != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            return nil;
//        }
//
//        cmdOutput = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
//        if (ssh.LastMethodSuccess != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            return nil;
//        }
//        NSArray * components = [cmdOutput componentsSeparatedByString:@"\r\n"];
//        if ([components count] > 2) {
//            if ([[NSString stringWithFormat:@"git %@",gitCommand] isEqualToString:components[0]]) {
//                [rDict setObject:components[1] forKey:gitCommand];
//            }
//        }
//    }
//
//    //  Send an EOF.  This tells the server that no more data will
//    //  be sent on this channel.  The channel remains open, and
//    //  the SSH client may still receive output on this channel.
//    success = [ssh ChannelSendEof: @(channelNum)];
//    if (success != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return nil;
//    }
//
//    //  Close the channel:
//    success = [ssh ChannelSendClose: @(channelNum)];
//    if (success != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return nil;
//    }
//
//    return rDict;
//}

-(void)sendDashCommandList:(NSArray*)commands onSSH:(CkoSsh *)ssh error:(NSError**)error {
    [self sendDashCommandList:commands onSSH:ssh commandExpectedLineCounts:nil error:error percentageClb:nil];
}


-(void)sendDashCommandList:(NSArray*)commands onSSH:(CkoSsh *)ssh commandExpectedLineCounts:(NSArray*)expectedlineCounts error:(NSError**)error percentageClb:(dashPercentageClb)clb {
    [self sendCommandList:commands toPath:@"~/src/dash" onSSH:ssh commandExpectedLineCounts:expectedlineCounts error:error percentageClb:clb];
}

-(void)sendCommandList:(NSArray*)commands toPath:(NSString*)path onSSH:(CkoSsh *)ssh error:(NSError**)error {
    [self sendCommandList:commands toPath:path onSSH:ssh commandExpectedLineCounts:nil error:error percentageClb:nil];
}

-(void)sendCommandList:(NSArray*)commands toPath:(NSString*)path onSSH:(CkoSsh *)ssh commandExpectedLineCounts:(NSArray*)expectedlineCounts error:(NSError**)error percentageClb:(dashPercentageClb)clb {
    //expected line counts are used to give back a percentage complete on this function;
    
    NSInteger channelNum = [[ssh QuickShell] integerValue];
    if (channelNum < 0) {
        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //  This is the prompt we'll be expecting to find in
    //  the output of the remote shell.
    NSString *myPrompt = [NSString stringWithFormat:@":%@$",path];
    //   Run the 1st command in the remote shell, which will be to
    //   "cd" to a subdirectory.
    BOOL success = [ssh ChannelSendString: @(channelNum) strData:[NSString stringWithFormat:@"cd %@\n",path] charset: @"ansi"];
    if (success != YES) {
        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //    NSNumber * v = [ssh ChannelReadAndPoll:@(channelNum) pollTimeoutMs:@(5000)];
    //
    //    NSString *cmdOutpu2t = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
    //    if (ssh.LastMethodSuccess != YES) {
    //        NSLog(@"%@",ssh.LastErrorText);
    //        return nil;
    //    };
    //  Retrieve the output.
    success = [ssh ChannelReceiveUntilMatch: @(channelNum) matchPattern: myPrompt charset: @"ansi" caseSensitive: YES];
    if (success != YES) {
        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //   Display what we've received so far.  This clears
    //   the internal receive buffer, which is important.
    //   After we send the command, we'll be reading until
    //   the next command prompt.  If the command prompt
    //   is already in the internal receive buffer, it'll think it's
    //   already finished...
    NSString *cmdOutput = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
    if (ssh.LastMethodSuccess != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    };
    NSMutableDictionary * rDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
    for (NSUInteger index = 0;index<[commands count];index++) {
        NSString * command = [commands objectAtIndex:index];
        NSNumber * numberLines = ([expectedlineCounts count] > index)?[expectedlineCounts objectAtIndex:index]:nil;
        //   Run the 2nd command in the remote shell, which will be
        //   to "ls" the directory.
        success = [ssh ChannelSendString: @(channelNum) strData:[NSString stringWithFormat:@"%@\n",command] charset: @"ansi"];
        if (success != YES) {
            *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
            NSLog(@"%@",ssh.LastErrorText);
            return;
        }
        if (numberLines && [numberLines integerValue] > 1) {
            NSMutableString * mOutput = [NSMutableString string];
            while (1) {
                NSNumber * poll = [ssh ChannelReadAndPoll: @(channelNum) pollTimeoutMs:@(3000)];
                if ([poll integerValue] == -1) {
                    *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
                    NSLog(@"%@",ssh.LastErrorText);
                    return;
                } else if ([poll integerValue] > 0) {
                    [mOutput appendString:[ssh GetReceivedText: @(channelNum) charset: @"ansi"]];
                    NSUInteger numberOfLines, index, stringLength = [mOutput length];
                    
                    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
                        index = NSMaxRange([mOutput lineRangeForRange:NSMakeRange(index, 0)]);
                    clb(command,numberOfLines / [numberLines floatValue]);
                }
                if ([[mOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix:myPrompt]) {
                    clb(command,1.0);
                    [rDict setObject:[mOutput copy] forKey:command];
                    break;
                }
            }
        } else {
            //  Retrieve and display the output.
            success = [ssh ChannelReceiveUntilMatch: @(channelNum) matchPattern: myPrompt charset: @"ansi" caseSensitive: YES];
            if (success != YES) {
                *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
                NSLog(@"%@",ssh.LastErrorText);
                return;
            }
            clb(command,1.0);
            cmdOutput = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
            if (ssh.LastMethodSuccess != YES) {
                *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
                NSLog(@"%@",ssh.LastErrorText);
                return;
            }
            [rDict setObject:cmdOutput forKey:command];
        }
    }
    
    //  Send an EOF.  This tells the server that no more data will
    //  be sent on this channel.  The channel remains open, and
    //  the SSH client may still receive output on this channel.
    success = [ssh ChannelSendEof: @(channelNum)];
    if (success != YES) {
        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //  Close the channel:
    success = [ssh ChannelSendClose: @(channelNum)];
    if (success != YES) {
        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
}

-(CkoSshKey *)loginPrivateKeyAtPath:(NSString*)path {
    CkoSshKey *key = [[CkoSshKey alloc] init];
    
    //  Read the PEM file into a string variable:
    //  (This does not load the PEM file into the key.  The LoadText
    //  method is a convenience method for loading the full contents of ANY text
    //  file into a string variable.)
    NSString *privKey = [key LoadText:path];
    if (key.LastMethodSuccess != YES) {
        NSLog(@"%@",key.LastErrorText);
        return nil;
    }
    
    //  Load a private key from a PEM string:
    //  (Private keys may be loaded from OpenSSH and Putty formats.
    //  Both encrypted and unencrypted private key file formats
    //  are supported.  This example loads an unencrypted private
    //  key in OpenSSH format.  PuTTY keys typically use the .ppk
    //  file extension, while OpenSSH keys use the PEM format.
    //  (For PuTTY keys, call FromPuttyPrivateKey instead.)
    BOOL success = [key FromOpenSshPrivateKey: privKey];
    if (success != YES) {
        NSLog(@"%@",key.LastErrorText);
        return nil;
    }
    return key;
}

-(CkoSFtp*)sftpIn:(NSString*)masternodeIP {
    if (![self sshPath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"SSH_KEY.pem" exPath:@"~/Documents"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [self setSshPath:pathString];
            return [self sftpIn:masternodeIP privateKeyPath:pathString];
        }
    }
    else{
        return [self sftpIn:masternodeIP privateKeyPath:[self sshPath]];
    }
    
    return nil;
}

-(CkoSFtp*)sftpIn:(NSString*)masternodeIP privateKeyPath:(NSString*)privateKeyPath {
    //  Important: It is helpful to send the contents of the
    //  sftp.LastErrorText property when requesting support.
    
    CkoSFtp *sftp = [[CkoSFtp alloc] init];
    
    //  Any string automatically begins a fully-functional 30-day trial.
    BOOL success = [sftp UnlockComponent: @"Anything for 30-day trial"];
    if (success != YES) {
        NSLog(@"%@",sftp.LastErrorText);
        return nil;
    }
    
    //  Set some timeouts, in milliseconds:
    sftp.ConnectTimeoutMs = [NSNumber numberWithInt:15000];
    sftp.IdleTimeoutMs = [NSNumber numberWithInt:15000];
    
    //  Connect to the SSH server.
    //  The standard SSH port = 22
    //  The hostname may be a hostname or IP address.
    int port = 22;
    NSString *hostname = masternodeIP;
    success = [sftp Connect: hostname port: [NSNumber numberWithInt: port]];
    if (success != YES) {
        NSLog(@"%@",sftp.LastErrorText);
        return nil;
    }
    
    CkoSshKey * key = [self loginPrivateKeyAtPath:privateKeyPath];
    if (!key) return nil;
    //  Authenticate with the SSH server using the login and
    //  private key.  (The corresponding public key should've
    //  been installed on the SSH server beforehand.)
    success = [sftp AuthenticatePk: @"ubuntu" privateKey: key];
    if (success != YES) {
        NSLog(@"%@",sftp.LastErrorText);
        return nil;
    }
    NSLog(@"%@",@"Public-Key Authentication Successful!");
    
    //  After authenticating, the SFTP subsystem must be initialized:
    success = [sftp InitializeSftp];
    if (success != YES) {
        NSLog(@"%@",sftp.LastErrorText);
        return nil;
    }
    return sftp;
}

- (BOOL)setUpMainNode:(NSManagedObject*)masternode {
    NSError *error;
    
    NSDictionary *dictionary = [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"mnsync status" toMasternode:masternode error:&error];
    if(dictionary == nil || ![dictionary valueForKey:@"AssetName"]) {
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: the dash core server of main node is not started", [masternode valueForKey:@"publicIP"]]];
        return NO;
    }
    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: mnsync status: %@", [masternode valueForKey:@"publicIP"], [dictionary valueForKey:@"AssetName"]]];
    
    if(![[dictionary valueForKey:@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:@"mnsync next"];
        [[DPMasternodeController sharedInstance] sendRPCCommandString:@"mnsync next" toMasternode:masternode];
        [self setUpMainNode:masternode];
    }
    else {
        //generate 1 block to activate masternode synchronization.
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: executing command: generate 1", [masternode valueForKey:@"publicIP"]]];
        [[DPMasternodeController sharedInstance] sendRPCCommandString:@"generate 1" toMasternode:masternode];
        return YES;
    }
    return YES;
}

- (void)addNodeToLocal:(NSManagedObject*)masternode clb:(dashClb)clb {
    
    NSString *port = @"19998";
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        port = @"12999";
    }
    NSString *command = [NSString stringWithFormat:@"addnode %@:%@ add", [masternode valueForKey:@"publicIP"], port];
    
    NSString *response = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:command forChain:chainNetwork];
    clb(YES, response);
}

- (void)addNodeToRemote:(NSManagedObject*)masternode toPublicIP:(NSString*)publicIP clb:(dashClb)clb {
    NSString *port = @"19998";
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        port = @"12999";
    }
    
    NSError *error;
    NSDictionary *dictionary = [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"getinfo" toMasternode:masternode error:&error];
    if(dictionary == nil || ![dictionary valueForKey:@"blocks"]) {
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: The dash core server is not started", [masternode valueForKey:@"publicIP"]]];
        return clb(NO,nil);
    }
    
    
    NSString *command = [NSString stringWithFormat:@"addnode %@:%@ add", publicIP, port];
    
    NSString *response = [[DPMasternodeController sharedInstance] sendRPCCommandString:command toMasternode:masternode];
    //generate 1 block to activate masternode synchronization.
    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: executing command: generate 1", [masternode valueForKey:@"publicIP"]]];
    [[DPMasternodeController sharedInstance] sendRPCCommandString:@"generate 1" toMasternode:masternode];
    clb(YES, response);
}


- (void)setUpMasternodeDashd:(NSManagedObject*)masternode clb:(dashClb)clb
{
//    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
//    __block NSString * repositoryPath = [masternode valueForKeyPath:@"branch.repository.url"];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
//        CkoSsh * ssh = [self sshIn:publicIP] ;
//        if (!ssh){
//            dispatch_async(dispatch_get_main_queue(), ^{
//                clb(NO,@"Could not SSH in");
//            });
//            return;
//        }
//        //  Send some commands and get the output.
//        NSString *strOutput = [ssh QuickCommand: @"ls src | grep '^dash$'" charset: @"ansi"];
//        if (ssh.LastMethodSuccess != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                clb(NO,ssh.LastErrorText);
//            });
//            return;
//        }
//        if ([strOutput hasPrefix:@"ls: cannot access src: No such file or directory"]) {
//            [ssh QuickCommand: @"mkdir src" charset: @"ansi"];
//            if (ssh.LastMethodSuccess != YES) {
//                NSLog(@"%@",ssh.LastErrorText);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    clb(NO,ssh.LastErrorText);
//                });
//                return;
//            }
//        }
//        BOOL justCloned = FALSE;
//        if (![strOutput isEqualToString:@"dash"]) {
//            justCloned = TRUE;
//            NSError * error = nil;
//            [self sendDashGitCloneCommandForRepositoryPath:repositoryPath toDirectory:@"~/src/dash" onSSH:ssh error:&error percentageClb:^(NSString *call, float percentage) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSLog(@"%@ %.2f",call,percentage);
//                    [masternode setValue:@(percentage) forKey:@"operationPercentageDone"];
//                });
//            }];
//            strOutput = [ssh QuickCommand: [NSString stringWithFormat:@"git clone %@ ~/src/dash",repositoryPath] charset: @"ansi"];
//            if (ssh.LastMethodSuccess != YES) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    clb(NO,ssh.LastErrorText);
//                });
//
//                return;
//            }
//        }
//
//        //now let's get git info
//        __block NSDictionary * gitValues = nil;
//        if (!justCloned) {
//            gitValues = [self sendGitCommands:@[@"pull",@"rev-parse --short HEAD"] onSSH:ssh];
//        } else {
//            gitValues = [self sendGitCommands:@[@"rev-parse --short HEAD"] onSSH:ssh];
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [masternode setValue:gitValues[@"rev-parse --short HEAD"] forKey:@"gitCommit"];
//            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
//        });
//
//        NSError * error = nil;
//
//        //now let's make all this shit
//        [self sendDashCommandList:@[@"./autogen.sh",@"./configure CPPFLAGS='-I/usr/local/BerkeleyDB.4.8/include -O2' LDFLAGS='-L/usr/local/BerkeleyDB.4.8/lib'",@"make",@"mkdir ~/.dashcore/",@"cp src/dashd ~/.dashcore/",@"cp src/dash-cli ~/.dashcore/",@"sudo cp src/dashd /usr/bin/dashd",@"sudo cp src/dash-cli /usr/bin/dash-cli"] onSSH:ssh commandExpectedLineCounts:@[@(52),@(481),@(301),@(1),@(1),@(1),@(1),@(1)] error:&error percentageClb:^(NSString *call, float percentage) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSLog(@"%@ %.2f",call,percentage);
//                [masternode setValue:@(percentage) forKey:@"operationPercentageDone"];
//            });
//        }];
//
//        [ssh Disconnect];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if ([[masternode valueForKey:@"masternodeState"] integerValue] == MasternodeState_Initial) {
//                [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
//            }
//            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
//        });
//    });
    
    
}

- (void)configureMasternodeSentinel:(NSArray*)AllMasternodes {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject *object in AllMasternodes)
        {
            if([[object valueForKey:@"isSelected"] integerValue] == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Configure sentinel.conf file for %@", [object valueForKey:@"publicIP"]]];
                });
                [self configureRemoteMasternodeSentinel:object clb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[self masternodeViewController] addStringEventToMasternodeConsole:message];
                    });
                }];
            }
        }
    });
}

- (void)setUpMasternodeConfiguration:(NSManagedObject*)masternode onChainName:(NSString*)chainName onSporkAddr:(NSString*)sporkAddr onSporkKey:(NSString*)sporkKey clb:(dashSuccessInfo)clb {
    
    __block NSManagedObject * object = masternode;
    
//    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: trying to start dashd on local...", [masternode valueForKey:@"instanceId"]];
//    clb(YES,eventMsg);
    
    if (![masternode valueForKey:@"key"] || [masternode valueForKey:@"key"] == nil) {
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ masternode genkey", [masternode valueForKey:@"chainNetwork"], [masternode valueForKey:@"instanceId"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(YES,eventMsg,NO);
        });
        
        NSString * key = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[NSString stringWithFormat:@"-%@ masternode genkey", [masternode valueForKey:@"chainNetwork"]] forChain:[masternode valueForKey:@"chainNetwork"]];
        
        if ([key length] >= 51) {
            if([key length] > 51) key = [key substringToIndex:[key length] - 1];
            [object setValue:key forKey:@"key"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
                [self setUpMasternodeConfiguration:object onChainName:chainName onSporkAddr:sporkAddr onSporkKey:sporkKey clb:clb];
            });
        }
        else {
            return clb(FALSE,@"Error generating masternode key",NO);
        }
        
        
//        [[DPLocalNodeController sharedInstance] startDash:^(BOOL success, NSString *message) {
//            if (!success) return clb(success,message);
//
//            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ masternode genkey", [masternode valueForKey:@"chainNetwork"], [masternode valueForKey:@"instanceId"]];
//            clb(YES,eventMsg);
//
//            NSString * key = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[NSString stringWithFormat:@"-%@ masternode genkey", [masternode valueForKey:@"chainNetwork"]] forChain:[masternode valueForKey:@"chainNetwork"]];
//            if ([key length] >= 51) {
//                if([key length] > 51) key = [key substringToIndex:[key length] - 1];
//                [object setValue:key forKey:@"key"];
//                [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
//                [self setUpMasternodeConfiguration:object onChainName:chainName clb:clb];
//            }
//            else {
//                if (!success) return clb(FALSE,@"Error generating masternode key");
//            }
//        } forChain:[masternode valueForKey:@"chainNetwork"]];
//        return;
    }
    
    if ([masternode valueForKey:@"transactionId"] && [masternode valueForKey:@"transactionOutputIndex"]) {
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configuring masternode configuration file...", [masternode valueForKey:@"instanceId"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(YES,eventMsg,NO);
            [[DPLocalNodeController sharedInstance] updateMasternodeConfigurationFileForMasternode:masternode clb:^(BOOL success, NSString *message) {
                if (success) {
                    [self configureRemoteMasternode:object clb:^(BOOL success, NSString *message) {
                        if(success != YES) {
                            return clb(success,message,NO);
                        }
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configure masternode configuration file successfully. Please wait for updating dash.conf file...", [masternode valueForKey:@"instanceId"]];
                        [[DPChainSelectionController sharedInstance] executeConfigurationMethod:[masternode valueForKey:@"chainNetwork"] onName:chainName onMasternode:masternode onSporkAddr:sporkAddr onSporkKey:sporkKey];
    
                        [masternode setValue:@(MasternodeState_Configured) forKey:@"masternodeState"];
                        [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
                        
                        clb(YES,eventMsg,YES);
                    }];
                }
                return clb(success,message,NO);
            }];
        });
    } else {
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configuring masternode configuration file...", [masternode valueForKey:@"instanceId"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(YES,eventMsg,NO);
        });
        
        NSMutableArray * outputs = [[[DPLocalNodeController sharedInstance] outputs:[masternode valueForKey:@"chainNetwork"]] mutableCopy];
        
        if(outputs == nil || [outputs count] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(FALSE,@"No valid outputs (empty) in local wallet.",NO);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *knownOutputs = [[[DPDataStore sharedInstance] allMasternodes] arrayOfArraysReferencedByKeyPaths:@[@"transactionId",@"transactionOutputIndex"] requiredKeyPaths:@[@"transactionId",@"transactionOutputIndex"]];
            for (int i = (int)[outputs count] -1;i> -1;i--) {
                for (NSArray * knownOutput in knownOutputs) {
                    if ([outputs[i][0] isEqualToString:knownOutput[0]] && ([outputs[i][1] integerValue] == [knownOutput[1] integerValue])) {
                        if(i < [outputs count]-1) [outputs removeObjectAtIndex:i];
                    }
                }
            }
            if ([outputs count]) {
                [masternode setValue:outputs[0][0] forKey:@"transactionId"];
                [masternode setValue:@([outputs[0][1] integerValue]) forKey:@"transactionOutputIndex"];
                [[DPDataStore sharedInstance] saveContext];
                [[DPLocalNodeController sharedInstance] updateMasternodeConfigurationFileForMasternode:masternode clb:^(BOOL success, NSString *message) {
                    if (success) {
                        [self configureRemoteMasternode:object clb:^(BOOL success, NSString *message) {
                            if(success != YES) {
                                return clb(success,message,NO);
                            }
                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configure masternode configuration file successfully. Please wait for updating dash.conf file...", [masternode valueForKey:@"instanceId"]];
                            [[DPChainSelectionController sharedInstance] executeConfigurationMethod:[masternode valueForKey:@"chainNetwork"] onName:chainName onMasternode:masternode onSporkAddr:sporkAddr onSporkKey:sporkKey];
                            
                            [masternode setValue:@(MasternodeState_Configured) forKey:@"masternodeState"];
                            [[DPDataStore sharedInstance] saveContext:object.managedObjectContext];
                            clb(YES,eventMsg,YES);
                        }];
                    }
                    return clb(success,message,NO);
                }];
            } else {
                return clb(FALSE,@"No valid outputs (1000 DASH) in local wallet.",NO);
            }
        });
    }
}

-(void)startDashdOnRemote:(NSManagedObject*)masternode onClb:(dashClb)clb {
    
    if(![masternode valueForKey:@"chainNetwork"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: please configure this instance before start it.", [masternode valueForKey:@"instanceId"]];
            clb(NO, eventMsg);
        });
        return;
    }
    
    //start dashd
    __block NMSSHSession *ssh;
    [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        ssh = sshSession;
        
    }];
    if(!ssh.authorized) {
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(NO,@"Could not SSH in");
        });
        return;
    }
    
    NSError *error = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: running dashd...", [masternode valueForKey:@"instanceId"]];
        clb(NO, eventMsg);
    });
    NSString *command;
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        command = [NSString stringWithFormat:@"cd ~/src/dash/src; ./dashd -%@ -rpcport=12998 -port=12999", chainNetwork];
    }
    else {
        command = [NSString stringWithFormat:@"cd ~/src; ./dashd"];
    }
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:ssh error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(NO, message);
        });
    }];
    
    if(error != nil) {
        NSLog(@"%@",[error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], [error localizedDescription]];
            clb(NO, eventMsg);
            return;
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Dash Core server is starting...", [masternode valueForKey:@"instanceId"]];
            clb(YES, eventMsg);
        });
    }
}

-(void)stopDashdOnRemote:(NSManagedObject*)masternode onClb:(dashClb)clb {
    
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    NSString *publicIP = [masternode valueForKey:@"publicIP"];
    NSString *rpcPassword = [masternode valueForKey:@"rpcPassword"];
    
    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ stop",[masternode valueForKey:@"instanceId"], chainNetwork, publicIP, rpcPassword];
    clb(NO, eventMsg);
    
    NSString *dataString = [self sendRPCCommandString:@"stop" toMasternode:masternode];
    if(dataString != nil) clb(NO, dataString);
}

- (void)setUpMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb {
    
    [masternode setValue:@(SentinelState_Checking) forKey:@"sentinelState"];
    [[DPDataStore sharedInstance] saveContext];
    
    __block NSString *localChain = [[DPDataStore sharedInstance] chainNetwork];
    __block NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(success == YES) {

                __block BOOL isContinue = true;
                
                NSError *error = nil;
                NSString *command = @"sudo apt-get update";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(isContinue, message);
                    });
                }];
                if(isContinue == NO) return;
                
                command = @"sudo apt-get install -y git python-virtualenv";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(isContinue, message);
                    });
                }];
                if(isContinue == NO) return;
                
                [[SshConnection sharedInstance] sendDashGitCloneCommandForRepositoryPath:@"https://github.com/dashpay/sentinel.git" toDirectory:@"~/.dashcore/sentinel" onSSH:sshSession onBranch:@"develop" error:error dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(isContinue, message);
                    });
                }];
                if(isContinue == NO) return;
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(success, message);
                    });
                }];
                
                command = @"cd ~/.dashcore/sentinel; virtualenv venv";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    if(success == NO){
                        dispatch_async(dispatch_get_main_queue(), ^{
                           clb(YES, message);
                        });
                        
                        //if failed try another command
                        NSString *command = @"cd ~/.dashcore/sentinel; sudo apt-get install -y virtualenv";
                        
                        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                            isContinue = success;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                clb(isContinue, message);
                            });
                        }];
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                           clb(YES, message);
                        });
                    }
                }];
                if(isContinue == NO) return;
                
                command = @"cd ~/.dashcore/sentinel; venv/bin/pip install -r requirements.txt";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(isContinue, message);
                    });
                }];
                if(isContinue == NO) return;
                
                //configure sentinel.conf
                
                
//                test sentinel is alive and talking to the still sync'ing wallet
//
//                venv/bin/python bin/sentinel.py
//
//                You should see: "dashd not synced with network! Awaiting full sync before running Sentinel."
//                This is exactly what we want to see at this stage
                command = @"cd ~/.dashcore/sentinel; venv/bin/python bin/sentinel.py";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(isContinue, message);
                    });
                }];
                if(isContinue == NO) return;
                
                error = nil;
                NSDictionary * dictionary = [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:[masternode valueForKey:@"publicIP"] rpcPassword:[masternode valueForKey:@"rpcPassword"] error:&error forChain:chainNetwork];
                
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
                        clb(NO,eventMsg);
                    });
                } else {
                    if (dictionary) {
                        if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                [[DPDataStore sharedInstance] saveContext];
                                [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                    if (!success) {
                                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                        clb(NO,eventMsg);
                                    } else  if (value) {
                                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
                                        clb(YES,eventMsg);
                                    }
                                }];
                            });
                        }
                        else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                clb(NO,@"Sync in progress. Must wait until sync is complete to start Masternode.");
                            });
                        }
                    }
                }
                
                command = @"echo \"$(echo '* * * * * cd /home/ubuntu/.dashcore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log' ; crontab -l)\" | crontab -";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isContinue = success;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(isContinue, message);
                    });
                }];
                if(isContinue == NO) return;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@(SentinelState_Installed) forKey:@"sentinelState"];
                    [[DPDataStore sharedInstance] saveContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO, @"SSH: could not SSH in!");
                });
            }
        }];
    });
}

- (void)checkMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(success == YES) {
                
                NSError *error = nil;
                NSString *command = @"cd ~/.dashcore/sentinel; venv/bin/python bin/sentinel.py";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(success, message);
                    });
                }];
            }
        }];
    });
}

- (void)configureRemoteMasternode:(NSManagedObject*)masternode clb:(dashClb)clb {
    
    [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        if(success == YES) {
            NSString *localFilePath = [self createConfigDashFileForMasternode:masternode];
            NSString *remoteFilePath = @"/home/ubuntu/.dashcore/dash.conf";
            
            __block BOOL isSuccess = YES;
            NSError *error = nil;
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore" onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                isSuccess = success;
            }];
            if(isSuccess != YES) {
                [[SshConnection sharedInstance] sendExecuteCommand:@"mkdir .dashcore" onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    isSuccess = success;
                }];
            }
            if(isSuccess != YES) return;
            
            BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
            if (uploadSuccess != YES) {
                NSLog(@"%@",[[sshSession lastError] localizedDescription]);
                clb(NO, [[sshSession lastError] localizedDescription]);
            }
            else {
                clb(YES, nil);
            }
        }
    }];
}

- (void)configureRemoteMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb {
    
    [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        if(success == YES) {
            NSString *localFilePath = [self createSentinelConfFileForMasternode:masternode];
            
            NSString *remoteFilePath = @"/home/ubuntu/.dashcore/sentinel/sentinel.conf";
            
            BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
            if (uploadSuccess != YES) {
                NSLog(@"%@",[[sshSession lastError] localizedDescription]);
                clb(NO, [[sshSession lastError] localizedDescription]);
            }
            else {
                clb(YES, @"Success");
            }
        }
    }];
}

#pragma mark - Reseting Data

-(void)wipeDataOnRemote:(NSManagedObject*)masternode onClb:(dashClb)clb {
    if([masternode valueForKey:@"publicIP"] == nil) return;
    __block NSString * chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if (!chainNetwork || [chainNetwork isEqualToString:@""]) return;
    chainNetwork = [chainNetwork stringByReplacingOccurrencesOfString:@"=" withString:@"-"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            
            if(success != YES) return;
            
            __block BOOL isSuccess = YES;
            NSError *error = nil;
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/.dashcore/%@",chainNetwork] onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                isSuccess = success;
            }];
            if(isSuccess != YES) return;
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"mv ~/.dashcore/%@/wallet.dat ~/.dashcore/%@/wallet",chainNetwork,chainNetwork] onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
            }];

            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/.dashcore/%@; (rm *.dat || true) && (rm *.log || true) && rm -rf blocks && rm -rf chainstate && rm -rf database && rm -rf evodb",chainNetwork] onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
            }];
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"mv ~/.dashcore/%@/wallet ~/.dashcore/%@/wallet.dat",chainNetwork,chainNetwork] onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
            }];
        }];
    });
}


#pragma mark - Start Remote

- (void)startMasternodeOnRemote:(NSManagedObject*)masternode localChain:(NSString*)localChain clb:(dashInfoClb)clb {
    
    if(![masternode valueForKey:@"chainNetwork"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: please configure this instance before start it.", [masternode valueForKey:@"instanceId"]];
            clb(NO,nil, eventMsg);
        });
        return;
    }
    
    if ([[masternode valueForKey:@"syncStatus"] integerValue] == MasternodeSync_Finished) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            __block NMSSHSession *ssh;
            [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                ssh = sshSession;
                
            }];
            if(!ssh.authorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,nil,@"Could not SSH in");
                });
                return;
            }
            
            [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                if (!success || !value) {
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                    clb(FALSE,nil,eventMsg);
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternode setValue:@(MasternodeState_Running) forKey:@"masternodeState"];
                        [[DPDataStore sharedInstance] saveContext];
                    });
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                    clb(TRUE,nil,eventMsg);
                }
            }];
        });
    } else if ([[masternode valueForKey:@"syncStatus"] integerValue] == MasternodeSync_Initial) {
        __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
        __block NSString * rpcPassword = [masternode valueForKey:@"rpcPassword"];
        __block NSString * chainNetwork = [masternode valueForKey:@"chainNetwork"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            
            __block NMSSHSession *ssh;
            [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                ssh = sshSession;
                
            }];
            if(!ssh.authorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,nil,@"Could not SSH in");
                });
                return;
            }
            
            NSString * previousSyncStatus = @"MASTERNODE_SYNC_INITIAL";
            int countConnect = 0;
            while (1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ mnsync status", [masternode valueForKey:@"instanceId"], chainNetwork, publicIP, rpcPassword];
                    clb(TRUE, nil, eventMsg);
                });
                NSError * error = nil;
                NSDictionary * dictionary = [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:publicIP rpcPassword:rpcPassword error:&error forChain:chainNetwork];
                countConnect = countConnect+1;
                
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error trying to start remote server. Dashd might not be started.", [masternode valueForKey:@"instanceId"]];
                        clb(FALSE, dictionary, eventMsg);
                    });
//                    break;
                } else {
                    if (dictionary) {
                        if (![previousSyncStatus isEqualToString:dictionary[@"AssetName"]]) {
                            if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                    [[DPDataStore sharedInstance] saveContext];
                                    [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                        if (!success) {
                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                            clb(FALSE, dictionary, eventMsg);
                                            clb(NO,dictionary,errorMessage);
                                        } else  if (value) {
                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@ \n start remote successfully.", [masternode valueForKey:@"instanceId"], dictionary];
                                            clb(TRUE, dictionary, eventMsg);
                                            clb(YES,dictionary,nil);
                                        }
                                        else {
                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                            clb(NO,nil,eventMsg);
                                        }
                                    }];
                                });
                                break;
                            }else if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FAILED"]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
                                    clb(FALSE, dictionary, eventMsg);
                                    clb(NO,dictionary,nil);
                                    [[DPDataStore sharedInstance] saveContext];
                                });
                                break;
                            }else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                    [[DPDataStore sharedInstance] saveContext];
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: could not start this masternode. Mnsync status: %@", [masternode valueForKey:@"instanceId"], dictionary[@"AssetName"]];
                                    clb(FALSE, dictionary, eventMsg);
                                });
                                break;
                            }
                        }
                        else if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_INITIAL"]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error: Sync in progress. Must wait until sync is complete to start Masternode.", [masternode valueForKey:@"instanceId"]];
                                clb(FALSE, nil, eventMsg);
                            });
                            break;
                        }
                    }
                }
                if(countConnect >= 10) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error: could not retrieve server information! Make sure dashd on remote is actually started.", [masternode valueForKey:@"instanceId"]];
                        clb(FALSE, nil, eventMsg);
                    });
                    break;
                }
                sleep(5);
            }
            [ssh disconnect];
        });
    } else {
        __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
        __block NSString * rpcPassword = [masternode valueForKey:@"rpcPassword"];
        __block NSString * chainNetwork = [masternode valueForKey:@"chainNetwork"];
        __block NSString * previousSyncStatus = [MasternodeSyncStatusTransformer typeNameForType:[[masternode valueForKey:@"syncStatus"] unsignedIntegerValue]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
//            CkoSsh * ssh = [self sshIn:publicIP] ;
//            if (!ssh){
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    clb(NO,nil,@"Could not SSH in");
//                });
//                return;
//            }
            //  Send some commands and get the output.
            
            __block NMSSHSession *ssh;
            [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                ssh = sshSession;
                
            }];
            if(!ssh.authorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,nil,@"Could not SSH in");
                });
                return;
            }
            
            int countConnect = 0;
            while (1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ mnsync status",[masternode valueForKey:@"instanceId"], chainNetwork, publicIP, rpcPassword];
                    clb(TRUE, nil, eventMsg);
                });
                NSError * error = nil;
                NSDictionary * dictionary = [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:publicIP rpcPassword:rpcPassword error:&error forChain:chainNetwork];
                
                countConnect = countConnect+1;
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error trying to start remote server. Dashd might not be started.", [masternode valueForKey:@"instanceId"]];
                        clb(FALSE, dictionary, eventMsg);
                    });
                } else {
                    if (dictionary) {
                        if (![previousSyncStatus isEqualToString:dictionary[@"AssetName"]]) {
                            if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                    [[DPDataStore sharedInstance] saveContext];
                                    [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                        if (!success) {
                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                            clb(FALSE, dictionary, eventMsg);
                                            clb(NO,dictionary,errorMessage);
                                        } else  if (value) {
                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
                                            clb(TRUE, dictionary, eventMsg);
                                            clb(YES,dictionary,nil);
                                        }
                                        else {
                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                            clb(NO,nil,eventMsg);
                                        }
                                    }];
                                });
                                break;
                            }else if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FAILED"]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
                                    clb(FALSE, dictionary, eventMsg);
                                    clb(NO,dictionary,nil);
                                    [[DPDataStore sharedInstance] saveContext];
                                });
                                break;
                            }else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                                    [[DPDataStore sharedInstance] saveContext];
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: could not start this masternode.  Mnsync status: %@", [masternode valueForKey:@"instanceId"], dictionary[@"AssetName"]];
                                    clb(FALSE, dictionary, eventMsg);
                                });
                                break;
                            }
                        }
                    }
                }
                if(countConnect >= 10) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error: could not retrieve server information! Make sure dashd on remote is actually started.", [masternode valueForKey:@"instanceId"]];
                        clb(FALSE, nil, eventMsg);
                    });
                    break;
                }
                sleep(5);
            }
//            [ssh Disconnect];
        });
    }
}

- (void)startRemoteMasternode:(NSManagedObject*)masternode localChain:(NSString*)localChain clb:(dashBoolClb)clb {
    
    BOOL isDevnet = NO;
    
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        chainNetwork = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999", chainNetwork];
        isDevnet = YES;
    }
    else {
        chainNetwork = [NSString stringWithFormat:@"-%@", chainNetwork];
    }
    
    if(isDevnet == YES) {
        [self registerProtxForLocal:[masternode valueForKey:@"publicIP"] localChain:localChain onClb:^(BOOL success, NSString *message) {
            clb(success, success, message);
        }];
    }
    else {
        NSString * string = [NSString stringWithFormat:@"%@ masternode start-alias %@", chainNetwork, [masternode valueForKey:@"instanceId"]];
        clb(NO, NO, string);
        
        __block NSData *data;
        [[DPLocalNodeController sharedInstance] runDashRPCCommand:string checkError:YES onClb:^(BOOL success, NSString *message, NSData *data2) {
            data = data2;
        }];
        NSError * error = nil;
        NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error) {
            if(dictionary)
            {
                return clb(NO,NO,dictionary[@"errorMessage"]);
            }
            else {
                return clb(NO,NO,[error localizedDescription]);
            }
        }
        if (dictionary && [dictionary[@"result"] isEqualToString:@"successful"]) clb(YES,YES,@"masternode started");
        else {
            if(dictionary && dictionary[@"errorMessage"])
            {
                return clb(NO,NO,dictionary[@"errorMessage"]);
            }
            else {
                return clb(NO,NO,dictionary[@"result"]);
            }
        }
    }
    
    
}

#pragma mark - RPC Query Remote

-(NSData *)sendRPCCommand:(NSString*)command toPublicIP:(NSString*)publicIP rpcPassword:(NSString*)rpcPassword forChain:(NSString*)chainNetwork {
    if([chainNetwork length] == 0 || chainNetwork == nil) {
        chainNetwork = @"mainnet";
    }
    else if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        chainNetwork = [NSString stringWithFormat:@"%@ -rpcport=12998 -port=12999", chainNetwork];
    }
    else {
        chainNetwork = [NSString stringWithFormat:@"%@", chainNetwork];
    }
    NSString * fullCommand = [NSString stringWithFormat:@"-%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ %@",chainNetwork,publicIP,rpcPassword, command];
    __block NSData *dataReturn;
    [[DPLocalNodeController sharedInstance] runDashRPCCommand:fullCommand checkError:YES onClb:^(BOOL success, NSString *message, NSData *data) {
        dataReturn = data;
    }];
    if(dataReturn != nil) return dataReturn;
    else return nil;
}

-(NSData *)sendRPCCommand:(NSString*)command toMasternode:(NSManagedObject*)masternode {
    return [self sendRPCCommand:command toPublicIP:[masternode valueForKey:@"publicIP"] rpcPassword:[masternode valueForKey:@"rpcPassword"] forChain:[masternode valueForKey:@"chainNetwork"]];
}

-(NSDictionary *)sendRPCCommandJSONDictionary:(NSString*)command toPublicIP:(NSString*)publicIP rpcPassword:(NSString*)rpcPassword error:(NSError**)error
                                     forChain:(NSString*)chainNetwork {
    NSData * data = [self sendRPCCommand:command toPublicIP:publicIP rpcPassword:rpcPassword forChain:chainNetwork];
    if (!data || data.length == 0) return @{};
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

-(NSDictionary *)sendRPCCommandJSONDictionary:(NSString*)command toMasternode:(NSManagedObject*)masternode error:(NSError**)error {
    NSData * data = [self sendRPCCommand:command toMasternode:masternode];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

-(NSString *)sendRPCCommandString:(NSString*)command toMasternode:(NSManagedObject*)masternode {
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        chainNetwork = [NSString stringWithFormat:@"%@ -rpcport=12998 -port=12999", chainNetwork];
    }
    else {
        chainNetwork = [NSString stringWithFormat:@"%@", chainNetwork];
    }
    NSString * fullCommand = [NSString stringWithFormat:@"-%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ %@", chainNetwork,[masternode valueForKey:@"publicIP"],[masternode valueForKey:@"rpcPassword"], command];
    NSString *dataReturn = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:fullCommand forChain:nil];
    if(dataReturn != nil) return dataReturn;
    else return nil;
}

-(void)getInfo:(NSManagedObject*)masternode clb:(dashInfoClb)clb {
    __block NSString * publicIp = [masternode valueForKey:@"publicIP"];
    __block NSString * rpcPassword = [masternode valueForKey:@"rpcPassword"];
    __block NSString * chainNetwork = [masternode valueForKey:@"chainNetwork"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSError * error = nil;
        NSDictionary * dictionary = [self sendRPCCommandJSONDictionary:@"getinfo" toPublicIP:publicIp rpcPassword:rpcPassword error:&error forChain:chainNetwork];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                clb(NO,nil,[error localizedDescription]);
            } else {
                clb(YES,dictionary,nil);
            }
        });
    });
}

#pragma mark - SSH Query Remote

-(void)updateGitInfoForMasternode:(NSManagedObject*)masternode clb:(dashInfoClb)clb {
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    __block NSString * branchName = [masternode valueForKeyPath:@"branch.name"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        __block NMSSHSession *ssh;
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            ssh = sshSession;
        }];
        
        if (!ssh.isAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO,nil,@"SSH: error authenticating with server.");
            });
            return;
        }
        
        NSDictionary * gitValues = [self sendGitCommands:@[@"rev-parse --short HEAD",@"rev-parse --abbrev-ref HEAD",@"remote -v"] onSSH:ssh onPath:@"/src/dash"];
        [ssh disconnect];
        __block NSString * remote = nil;
        NSArray * remoteInfoLine = [gitValues[@"remote -v"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
        
        if (remoteInfoLine.count > 2 && [remoteInfoLine[2] isEqualToString:@"(fetch)"]) {
            remote = remoteInfoLine[1];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (remote) {
                NSManagedObject * branch = [[DPDataStore sharedInstance] branchNamed:gitValues[@"rev-parse --abbrev-ref HEAD"] onRepositoryURLPath:remote];
                if (branch && [branchName isEqualToString:[branch valueForKey:@"name"]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternode setValue:branch forKey:@"branch"];
                        if (clb) clb(YES,@{@"hasChanges":@(TRUE)},nil);
                    });
                    return;
                }
            }
            if (![[masternode valueForKey:@"gitCommit"] isEqualToString:gitValues[@"rev-parse --short HEAD"]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:gitValues[@"rev-parse --short HEAD"] forKey:@"gitCommit"];
                    if (clb) clb(YES,@{@"hasChanges":@(TRUE)},nil);
                });
                return;
            }
        });

//        CkoSsh * ssh = [self sshIn:publicIP];
//        if (!ssh) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                clb(NO,nil,@"Could not ssh in");
//            });
//            return;
//        }
//
//        NSDictionary * gitValues = [self sendGitCommands:@[@"rev-parse --short HEAD",@"rev-parse --abbrev-ref HEAD",@"remote -v"] onSSH:ssh];
//        [ssh Disconnect];
//        __block NSString * remote = nil;
//        NSArray * remoteInfoLine = [gitValues[@"remote -v"] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
//
//        if (remoteInfoLine.count > 2 && [remoteInfoLine[2] isEqualToString:@"(fetch)"]) {
//            remote = remoteInfoLine[1];
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (remote) {
//                NSManagedObject * branch = [[DPDataStore sharedInstance] branchNamed:gitValues[@"rev-parse --abbrev-ref HEAD"] onRepositoryURLPath:remote];
//                if (branch && [branchName isEqualToString:[branch valueForKey:@"name"]]) {
//                    [masternode setValue:branch forKey:@"branch"];
//                    return clb(YES,@{@"hasChanges":@(TRUE)},nil);
//                }
//            }
//            if (![[masternode valueForKey:@"gitCommit"] isEqualToString:gitValues[@"rev-parse --short HEAD"]]) {
//                [masternode setValue:gitValues[@"rev-parse --short HEAD"] forKey:@"gitCommit"];
//                return clb(YES,@{@"hasChanges":@(TRUE)},nil);
//            }
//        });
        
    });
}

#pragma mark - SSH in info

-(void)retrieveConfigurationInfoThroughSSH:(NSManagedObject*)masternode clb:(dashInfoClb)clb {
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        __block NMSSHSession *ssh;
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            ssh = sshSession;
            if(!ssh.authorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,nil,@"Could not ssh in");
                });
                return;
            }
        }];
        
        NSError *error = nil;
        NSString *strOutput = [ssh.channel execute:@"cat .dashcore/dash.conf" error:&error];
        if(error) {
            NSLog(@"%@",[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO,nil,@"Could not retieve configuration file");
            });
            return;
        }
        [ssh disconnect];
        
        if([strOutput length] != 0 || strOutput != nil) {
            NSArray * lines = [strOutput componentsSeparatedByString:@"\n"];
            __block NSMutableDictionary * rDict = [NSMutableDictionary dictionary];
            for (NSString * line in lines) {
                if ([line hasPrefix:@"#"] || ![line containsString:@"="]) continue;
                NSArray * valueKeys =[line componentsSeparatedByString:@"="];
                [rDict setObject:valueKeys[1] forKey:valueKeys[0]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                return clb(YES,rDict,nil);
            });
        }
    });
    
}

#pragma mark - Masternode Checks

- (void)checkMasternodeIsInstalled:(NSManagedObject*)masternode clb:(dashBoolClb)clb {
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        __block NMSSHSession *ssh;
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            ssh = sshSession;
        }];
        
        if (!ssh.isAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO,NO,@"SSH: error authenticating with server.");
            });
            return;
        }
        
        NSError *error = nil;
        [ssh.channel execute:@"cd src/dash" error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [ssh disconnect];
            if (error) {
                return clb(YES,NO,nil);
            }
            else {
                return clb(YES,YES,nil);
            }
        });
        
        
//        CkoSsh * ssh = [self sshIn:publicIP];
//        if (!ssh) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                clb(NO,NO,@"Could not ssh in");
//            });
//            return;
//        }
//        //  Send some commands and get the output.
//        NSString *strOutput = [[ssh QuickCommand: @"ls src | grep '^dash$'" charset: @"ansi"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//        if (ssh.LastMethodSuccess != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            [ssh Disconnect];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                clb(NO,NO,@"ssh failure");
//            });
//            return;
//        }
//        [ssh Disconnect];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if ([strOutput isEqualToString:@"dash"]) {
//                return clb(YES,YES,nil);
//            }else {
//                return clb(YES,NO,nil);
//            }
//        });
    });
}


-(BOOL)checkMasternodeIsProperlyConfigured:(NSManagedObject *)masternode {
    return TRUE;
}

-(void)checkMasternodeChainNetwork:(NSManagedObject*)masternode {
    
    if([masternode valueForKey:@"publicIP"] == nil) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            
            if(success != YES) return;
            
            __block BOOL isSuccess = YES;
            NSError *error = nil;
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore" onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                isSuccess = success;
            }];
            if(isSuccess != YES) return;
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore && cat dash.conf" onSSH:sshSession error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                isSuccess = success;
                if(success == YES && message != nil){
                    NSArray *dashConf = [message componentsSeparatedByString:@"\n"];
                    NSString *chainString = @"";
                    
                    for(NSString *line in dashConf) {
                        if ([line rangeOfString:@"mainnet"].location != NSNotFound)
                        {
                            chainString = @"mainnet";
                            break;
                        }
                        else if ([line rangeOfString:@"testnet"].location != NSNotFound)
                        {
                            chainString = @"testnet";
                            break;
                        }
                        else if ([line rangeOfString:@"devnet"].location != NSNotFound)
                        {
                            NSArray *netArray = [line componentsSeparatedByString:@"="];
                            if([netArray count] == 2) {
                                chainString = [NSString stringWithFormat:@"devnet=%@",[netArray objectAtIndex:1]];
                            }
                            else {
                                chainString = @"devnet=none";
                            }
                            break;
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternode setValue:chainString forKey:@"chainNetwork"];
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternode setValue:@"Unknown" forKey:@"chainNetwork"];
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    });
                }
            }];
            if(isSuccess != YES) return;
        }];
    });
}

-(void)checkMasternodeIsProperlyInstalled:(NSManagedObject*)masternode onSSH:(NMSSHSession*)ssh {
    [self checkMasternodeIsProperlyInstalled:masternode onSSH:ssh dashClb:^(BOOL success, NSString *message) {
        
    }];
}

-(void)checkMasternodeIsProperlyInstalled:(NSManagedObject*)masternode onSSH:(NMSSHSession*)ssh dashClb:(dashClb)clb {
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        __block BOOL checkResult = NO;
        NSError *error;
        
        //does this masternode execute .autogen.sh?
        NSString *response = [ssh.channel execute:@"ls ~/src/dash/configure" error:&error];
        if(error || [response length] == 0) {//no
            
            [[SshConnection sharedInstance] sendDashCommandsList:@[@"autogen.sh",@"configure"] onSSH:ssh onPath:@"~/src/dash/" error:error dashClb:^(BOOL success, NSString *call) {
                NSLog(@"SSH-%@: %@", publicIP, call);
                clb(success,call);
                checkResult = success;
            }];
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:ssh error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                NSLog(@"SSH-%@: %@", publicIP, message);
                clb(success,message);
                checkResult = success;
            }];
        }
        else {//yes
            //does this masternode execute ./configure?
            NSString *response = [ssh.channel execute:@"ls ~/src/dash/Makefile" error:&error];
            if(error || [response length] == 0) {//no
                
                [[SshConnection sharedInstance] sendDashCommandsList:@[@"configure"] onSSH:ssh onPath:@"~/src/dash/" error:error dashClb:^(BOOL success, NSString *call) {
                    NSLog(@"SSH-%@: %@", publicIP, call);
                    clb(success,call);
                    checkResult = success;
                }];
                
                [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:ssh error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                    NSLog(@"SSH-%@: %@", publicIP, message);
                    clb(success,message);
                    checkResult = success;
                }];
            }
            else {//yes
                //does this masternode execute ./make?
                NSString *response = [ssh.channel execute:@"ls ~/src/dash/src/dashd" error:&error];
                if(error || [response length] == 0) {//no
                    
                    [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:ssh error:error mainThread:NO dashClb:^(BOOL success, NSString *message) {
                        NSLog(@"SSH-%@: %@", publicIP, message);
                        clb(success,message);
                        checkResult = success;
                    }];
                    
                }
                else {
                    clb(YES,nil);
                    checkResult = YES;
                }
            }
        }
        
        if(checkResult == YES) {
            [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
        }
        else {
            [masternode setValue:@(MasternodeState_SettingUp) forKey:@"masternodeState"];
            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
        }
    });
}

-(void)updateMasternodeAttributes:(NSManagedObject*)masternode {
    __block NSString *publicIP = [masternode valueForKey:@"publicIP"];
    __block NSString *rpcPassword = [masternode valueForKey:@"rpcPassword"];
    __block NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(success != YES) return;
            
            NSArray *gitCommand = [NSArray array];
            //check value "gitCommit
            gitCommand = [[NSArray alloc] initWithObjects:@"rev-parse --short HEAD", nil];
            NSDictionary * gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/src/dash"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(gitValues != nil) {
                    [masternode setValue:gitValues[@"rev-parse --short HEAD"] forKey:@"gitCommit"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                }
                else {
                    [masternode setValue:@"" forKey:@"gitCommit"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                }
            });
            
            //check value "branch.name"
            gitCommand = [[NSArray alloc] initWithObjects:@"branch", nil];
            gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/src/dash"];
            if(gitValues != nil) {
                NSArray *gitBranchArray = [[gitValues objectForKey:@"branch"] componentsSeparatedByString:@"\n"];
                NSString *gitBranch = @"";
                for(NSString *elements in gitBranchArray) {
                    if ([elements rangeOfString:@"*"].location != NSNotFound) {
                        NSArray *branchArray = [elements componentsSeparatedByString:@" "];
                        if([branchArray count] >= 2) gitBranch = [branchArray objectAtIndex:1];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:gitBranch forKey:@"gitBranch"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@"" forKey:@"gitBranch"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            
            //check value "sentinelGitCommit"
            gitCommand = [[NSArray alloc] initWithObjects:@"rev-parse --short HEAD", nil];
            gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/.dashcore/sentinel"];
            if(gitValues != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:gitValues[@"rev-parse --short HEAD"] forKey:@"sentinelGitCommit"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@"" forKey:@"sentinelGitCommit"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            
            //check value "sentinelGitBranch"
            gitCommand = [[NSArray alloc] initWithObjects:@"branch", nil];
            gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/.dashcore/sentinel"];
            if(gitValues != nil) {
                NSArray *gitBranchArray = [[gitValues objectForKey:@"branch"] componentsSeparatedByString:@"\n"];
                NSString *gitBranch = @"";
                for(NSString *elements in gitBranchArray) {
                    if ([elements rangeOfString:@"*"].location != NSNotFound) {
                        NSArray *branchArray = [elements componentsSeparatedByString:@" "];
                        if([branchArray count] >= 2) gitBranch = [branchArray objectAtIndex:1];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:gitBranch forKey:@"sentinelGitBranch"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@"" forKey:@"sentinelGitBranch"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            
            //check value "SyncState"
            NSError *error = nil;
            NSDictionary * dictionary = [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:publicIP rpcPassword:rpcPassword error:&error forChain:chainNetwork];
            dispatch_async(dispatch_get_main_queue(), ^{
                [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
                [[DPDataStore sharedInstance] saveContext];
            });
            
            //check value "repositoryUrl"
            gitCommand = [[NSArray alloc] initWithObjects:@"config --get remote.origin.url", nil];
            gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/src/dash"];
            if(gitValues != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:[gitValues valueForKey:@"config --get remote.origin.url"] forKey:@"repositoryUrl"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@"" forKey:@"repositoryUrl"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
        }];
    });
}

-(void)checkMasternode:(NSManagedObject*)masternode {
    if(![masternode valueForKey:@"publicIP"]) return;
    [self checkMasternodeChainNetwork:masternode];
    [self updateMasternodeAttributes:masternode];
    [self checkMasternode:masternode saveContext:TRUE clb:nil];
}

-(void)checkMasternode:(NSManagedObject*)masternode saveContext:(BOOL)saveContext clb:(dashClb)clb {
    //we are going to check if a masternode is running, configured, etc...
    //first let's check to see if we have access to rpc
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        if ([masternode valueForKey:@"rpcPassword"]) {
            //we most likely have access to rpc, it's running
            [self getInfo:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
                if (dictionary) {
                    [masternode setValue:@(MasternodeState_Running) forKey:@"masternodeState"];
                    [masternode setValue:dictionary[@"blocks"] forKey:@"lastBlock"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                } else {
                    [self checkMasternodeIsInstalled:masternode clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                        if (value) {
                            NSDictionary * dictionary = [[DPLocalNodeController sharedInstance] masternodeInfoInMasternodeConfigurationFileForMasternode:masternode];
                            if (dictionary && [dictionary[@"publicIP"] isEqualToString:[masternode valueForKey:@"publicIP"]]) {
                                [masternode setValuesForKeysWithDictionary:dictionary];
                                [masternode setValue:@(MasternodeState_Configured) forKey:@"masternodeState"];
                                if ([masternode hasChanges]) {
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }
                                [self updateGitInfoForMasternode:masternode clb:nil];
                            } else {
                                if ([[masternode valueForKey:@"masternodeState"] integerValue] != MasternodeState_Installed) {
                                    [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }
                                [self updateGitInfoForMasternode:masternode clb:nil];
                            }
                        } else {
                            if ([[masternode valueForKey:@"masternodeState"] integerValue] != MasternodeState_Initial) {
                                [masternode setValue:@(MasternodeState_Initial) forKey:@"masternodeState"];
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                            }
                        }
                    }];
                }
            }];
            
            
        } else { //we don't have access to the rpc, let's ssh in and retrieve it.
            [self retrieveConfigurationInfoThroughSSH:masternode clb:^(BOOL success, NSDictionary *info, NSString *errorMessage) {
                
                if (![info[@"externalip"] isEqualToString:[masternode valueForKey:@"publicIP"]]) {
                    //the masternode has never been configured
                    [self checkMasternodeIsInstalled:masternode clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                        if (value) {
                            if ([[masternode valueForKey:@"masternodeState"] integerValue] != MasternodeState_Installed) {
                                [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                            }
                            [self updateGitInfoForMasternode:masternode clb:nil];
                        } else {
                            if ([[masternode valueForKey:@"masternodeState"] integerValue] != MasternodeState_Initial) {
                                [masternode setValue:@(MasternodeState_Initial) forKey:@"masternodeState"];
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                            }
                        }
                    }];
                } else {
                    [masternode setValue:info[@"rpcpassword"] forKey:@"rpcPassword"];
                    [masternode setValue:info[@"masternodeprivkey"] forKey:@"key"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    [self getInfo:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
                        if (dictionary) {
                            [masternode setValue:@(MasternodeState_Running) forKey:@"masternodeState"];
                            [masternode setValue:dictionary[@"blocks"] forKey:@"lastBlock"];
                            [self updateGitInfoForMasternode:masternode clb:nil];
                            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                        } else {
                            [self checkMasternodeIsInstalled:masternode clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                if (value) {
                                    NSDictionary * dictionary = [[DPLocalNodeController sharedInstance] masternodeInfoInMasternodeConfigurationFileForMasternode:masternode];
                                    if (dictionary && [dictionary[@"publicIP"] isEqualToString:[masternode valueForKey:@"publicIP"]]) {
                                        [masternode setValuesForKeysWithDictionary:dictionary];
                                        [masternode setValue:@(MasternodeState_Configured) forKey:@"masternodeState"];
                                    } else {
                                        [masternode setValue:@(MasternodeState_Installed) forKey:@"masternodeState"];
                                    }
                                    if ([masternode hasChanges]) {
                                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                    }
                                    [self updateGitInfoForMasternode:masternode clb:nil];
                                } else {
                                    if ([[masternode valueForKey:@"masternodeState"] integerValue] != MasternodeState_Initial) {
                                        [masternode setValue:@(MasternodeState_Initial) forKey:@"masternodeState"];
                                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                    }
                                }
                            }];
                        }
                    }];
                }
            }];
            
        }
    });
}

#pragma mark - Masternode Fixes

- (BOOL)removeDatFilesFromMasternode:(NSManagedObject*)masternode {
    
    __block NMSSHSession *ssh;
    [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        ssh = sshSession;
    }];
    
    if(!ssh.authorized) {
        return FALSE;
    }
    
    NSError * error = nil;
    [[SshConnection sharedInstance] sendDashCommandsList:@[@"rm -rf {banlist,fee_estimates,budget,governance,mncache,mnpayments,netfulfilled,peers}.dat"] onSSH:ssh onPath:@"cd ~/.dashcore" error:error dashClb:^(BOOL success, NSString *call) {
        
    }];
    [ssh disconnect];
    
//    CkoSsh * ssh = [self sshIn:[masternode valueForKey:@"publicIP"]];
//    if (!ssh) return FALSE;
//    //now let's make all this shit
//    NSError * error = nil;
//    [self sendCommandList:@[@"rm -rf {banlist,fee_estimates,budget,governance,mncache,mnpayments,netfulfilled,peers}.dat"] toPath:@"~/.dashcore/" onSSH:ssh error:&error];
//
//    [ssh Disconnect];
    
    return TRUE;
    
    
}

#pragma mark - Sentinel Checks


#pragma mark - AWS Core

- (NSString *)runAWSCommandString:(NSString *)commandToRun checkError:(BOOL)withError
{
    
    NSString *output = [[NSString alloc] initWithData:[self runAWSCommand:commandToRun checkError:withError] encoding:NSUTF8StringEncoding];
    return output;
}

- (NSDictionary *)runAWSCommandJSON:(NSString *)commandToRun checkError:(BOOL)withError
{
    NSData * data = [self runAWSCommand:commandToRun checkError:withError];
    
    NSError * error = nil;
    NSDictionary *output = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &error];
    return output;
}

- (NSData *)runAWSCommand:(NSString *)commandToRun checkError:(BOOL)withError
{
    NSTask *task = [[NSTask alloc] init];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(![[PreferenceData sharedInstance] getAWSPath]) {
            [[DialogAlert sharedInstance] showWarningAlert:@"AWS" message:@"AWS path not found! Please set up your AWS path."];
        }
    });
    
    if(![[PreferenceData sharedInstance] getAWSPath]) return [NSData data];
    
//    [task setLaunchPath:@"/usr/local/bin/aws"];
    [task setLaunchPath:[[PreferenceData sharedInstance] getAWSPath]];
    
//    if([task isRunning])
//    {
//        NSLog(@"Aws is running!!");
//    }
//    else
//    {
//        NSLog(@"Aws not found!!");
//        return nil;
//    }
    
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];

    //TOEY, add newArguments variable to handle a case that has sentence like "We are developer".
    NSMutableArray *newArguments = [self getArgumentsWithSentence:arguments];

    NSLog(@"run command:%@", commandToRun);
    [task setArguments:newArguments];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];

    NSFileHandle *file = [pipe fileHandleForReading];

    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];

    NSFileHandle *error = [errorPipe fileHandleForReading];
    
    [task launch];

    if(withError == YES) {
        [task waitUntilExit]; //Toey, wait until finish launching task to show error.
        //Toey, add this stuff to show error alert.
        NSData * dataError = [error availableData];
        if(dataError != nil) {
            NSString * strError = [[NSString alloc] initWithData:dataError encoding:NSUTF8StringEncoding];
            if([strError length] != 0) {
                return dataError;
            }
        }
    }
    
    return [file readDataToEndOfFile];
}

-(NSMutableArray*)getArgumentsWithSentence:(NSArray*)arguments {
    
    NSMutableArray *newArguments = [[NSMutableArray alloc] init];
    NSString *str = @"";
    BOOL isConcating = false;
    
    for (NSString *string in arguments)
    {
//        if(terminalType) {
//            if(arguments[0])
//            {
//                terminalType = false;
//                continue;
//            }
//        }
        if([string length] == 0) continue;
        
        NSString *firstChar = [string substringToIndex:1];
        NSString *lastChar = [string substringFromIndex:[string length] - 1];
        
        if([firstChar isEqualToString:@"\""] && [lastChar isEqualToString:@"\""])
        {
            NSString *cutFirst = [string substringFromIndex:1];
            NSString *cutLast = [cutFirst substringToIndex:[cutFirst length] - 1];
            [newArguments addObject:cutLast];
        }
        else if([firstChar isEqualToString:@"\""]) {
            str = [str stringByAppendingString:string];
            isConcating = true;
        }
        else if([lastChar isEqualToString:@"\""])
        {
            str = [str stringByAppendingString:[NSString stringWithFormat:@" %@",string]];
            NSString *cutFirst = [str substringFromIndex:1];
            NSString *cutLast = [cutFirst substringToIndex:[cutFirst length] - 1];
            //            NSLog(@"%@", cutLast);
            [newArguments addObject:cutLast];
            isConcating = false;
            str = @"";
        }
        else{
            if(isConcating)
            {
                str = [str stringByAppendingString:[NSString stringWithFormat:@" %@",string]];
            }
            else{
                [newArguments addObject:string];
                //                NSLog(@"%@", string);
            }
        }
    }
    return newArguments;
}

#pragma mark - Instances

-(void)setUpInstances:(NSInteger)count onBranch:(NSManagedObject*)branch clb:(dashInfoClb)clb onRegion:(NSMutableArray*)regionArray serverType:(NSString*)serverType {
    
    if (![self sshPath] || ![[PreferenceData sharedInstance] getKeyName]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"SSH_KEY.pem" exPath:@"~/Documents"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSArray *fileInfo = [dialog getSSHLaunchPathAndName];
            [self setSshPath:fileInfo[1]];
            
            NSArray* nameArray = [fileInfo[0] componentsSeparatedByString: @"."];
            NSString* nameString = [nameArray objectAtIndex: 0];
            
            [self setSshName:nameString];
        }
    }
    
    if([[PreferenceData sharedInstance] getSecurityGroupId]
       ||[[PreferenceData sharedInstance] getSubnetID]
       ||[[PreferenceData sharedInstance] getKeyName])
    {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            
            //check repository's AMI
            NSString *imageId = @"";
            if([[branch valueForKey:@"amiId"] isEqualToString:@""] || [branch valueForKey:@"amiId"] == nil)
            {
                imageId = @"ami-78d69092"; //this is initial dash image id
            }
            else{
                imageId = [branch valueForKey:@"amiId"];
            }
            
            __block NSMutableDictionary * instances = [NSMutableDictionary dictionary];
            
            NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 run-instances --image-id %@ --count %ld --instance-type %@ --key-name %@ --security-group-ids %@ --instance-initiated-shutdown-behavior terminate --subnet-id %@ ",imageId,count,serverType,[[PreferenceData sharedInstance] getKeyName],[[PreferenceData sharedInstance] getSecurityGroupId],[[PreferenceData sharedInstance] getSubnetID]] checkError:NO];
            
            //NSLog(@"%@",reservation[@"Instances"]);
            for (NSDictionary * dictionary in output[@"Instances"]) {
                NSDictionary * rDict = [NSMutableDictionary dictionary];
                [rDict setValue:[dictionary valueForKey:@"InstanceId"] forKey:@"instanceId"];
                [rDict setValue:@(MasternodeState_Initial)  forKey:@"masternodeState"];
                [rDict setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                [instances setObject:rDict forKey:[dictionary valueForKey:@"InstanceId"]];
            }
            
        
            NSMutableArray * instanceIdsLeft = [[instances allKeys] mutableCopy];
            while ([instanceIdsLeft count]) {
                NSDictionary *output2 = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 describe-instances --instance-ids %@ --filter Name=key-name,Values=%@",[instanceIdsLeft componentsJoinedByString:@" "], [[PreferenceData sharedInstance] getKeyName]]  checkError:NO];
                NSArray * reservations = output2[@"Reservations"];
                for (NSDictionary * reservation in reservations) {
                    //NSLog(@"%@",reservation[@"Instances"]);
                    for (NSDictionary * dictionary in reservation[@"Instances"]) {
                        if ([dictionary valueForKey:@"PublicIpAddress"] && ![[dictionary valueForKeyPath:@"State.Name"] isEqualToString:@"pending"]) {
                            
                            [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[dictionary valueForKey:@"PublicIpAddress"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                if (sshSession.isAuthorized) {
                                    [[instances objectForKey:[dictionary valueForKey:@"InstanceId"]] setValue:[dictionary valueForKey:@"PublicIpAddress"] forKey:@"publicIP"];
                                    [[instances objectForKey:[dictionary valueForKey:@"InstanceId"]] setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                                    [instanceIdsLeft removeObject:[dictionary valueForKey:@"InstanceId"]];
                                    [sshSession disconnect];
                                }
                            }];
                        }
                    }
                }
                if (instanceIdsLeft) sleep(5);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray * masternodes = [self saveInstances:[instances allValues]];
                for (NSManagedObject * masternode in masternodes) {
                    [masternode setValue:branch forKey:@"branch"];
                    [[DPDataStore sharedInstance] saveContext];
                    [self setUpMasternodeDashd:masternode clb:^(BOOL success, NSString *message) {
                        if (!success) {
                            clb(NO,nil,message);
                            NSLog(@"");
                        }
                    }];
                }
                if([instances count] > 0) {
                    [[DialogAlert sharedInstance] showAlertWithOkButton:@"Instance" message:[NSString stringWithFormat:@"Created %lu instance(s) successfully.", [instances count]]];
                }
                else {
                    [[DialogAlert sharedInstance] showAlertWithOkButton:@"Instance" message:[NSString stringWithFormat:@"Something went wrong."]];
                }
            });
        });
    
    }
    else{
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create new instance!" message:@"Please configure your AWS account in preference window."];
    }
}

-(void)keepTabsOnInstance:(NSString*)instanceId clb:(dashStateClb)clb  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [NSTimer scheduledTimerWithTimeInterval:10 repeats:TRUE block:^(NSTimer * _Nonnull timer) {
            [self checkInstance:instanceId clb:^(BOOL success, InstanceState state, NSString *message) {
                if (!InstanceState_Transitional(state)) {
                    
                }
            }];
        }];
        
    });
}

- (void)runInstances:(NSInteger)count clb:(dashStateClb)clb serverType:(NSString*)serverType {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 run-instances --image-id ami-38ad8444 --count %ld --instance-type %@ --key-name %@ --security-group-ids %@ --instance-initiated-shutdown-behavior terminate --subnet-id %@",
                                                        (long)count,
                                                        serverType,
                                                        [[PreferenceData sharedInstance] getKeyName],
                                                        [[PreferenceData sharedInstance] getSecurityGroupId],
                                                        [[PreferenceData sharedInstance] getSubnetID]]  checkError:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (output[@"Instances"]) {
                NSMutableArray * instances = [NSMutableArray array];
                //NSLog(@"%@",reservation[@"Instances"]);
                for (NSDictionary * dictionary in output[@"Instances"]) {
                    NSDictionary * rDict = [NSMutableDictionary dictionary];
                    [rDict setValue:[dictionary valueForKey:@"InstanceId"] forKey:@"instanceId"];
                    [rDict setValue:[dictionary valueForKey:@"PublicIpAddress"] forKey:@"publicIP"];
                    [rDict setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                    [instances addObject:rDict];
                }
                [self saveInstances:instances];
            } else {
                clb(FALSE,InstanceState_Unknown,FS(@"Unable to process the creation of %ld instance%@",count,count>1?@"s":@""));
            }
        });
    });
}

- (void)startInstance:(NSString*)instanceId clb:(dashStateClb)clb  {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 start-instances --instance-ids %@",instanceId]  checkError:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (output[@"StartingInstances"]) {
                for (NSDictionary * instance in output[@"StartingInstances"]) {
                    if (instance[@"InstanceId"] && instance[@"CurrentState"] && instance[@"CurrentState"][@"Name"]) {
                        [[DPDataStore sharedInstance] updateMasternode:instance[@"InstanceId"] withState:[self stateForStateName:instance[@"CurrentState"][@"Name"]]];
                        clb(TRUE,[self stateForStateName:instance[@"CurrentState"][@"Name"]],instance[@"InstanceId"]);
                    }
                }
            } else {
                clb(FALSE,InstanceState_Unknown,@"Unable to process the start of instance(s)");
            }
        });
    });
}

- (void)stopInstance:(NSString*)instanceId clb:(dashStateClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 stop-instances --instance-ids %@",instanceId]  checkError:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (output[@"StoppingInstances"]) {
                for (NSDictionary * instance in output[@"StoppingInstances"]) {
                    if (instance[@"InstanceId"] && instance[@"CurrentState"] && instance[@"CurrentState"][@"Name"]) {
                        [[DPDataStore sharedInstance] updateMasternode:instance[@"InstanceId"] withState:[self stateForStateName:instance[@"CurrentState"][@"Name"]]];
                        clb(TRUE,[self stateForStateName:instance[@"CurrentState"][@"Name"]],instance[@"InstanceId"]);
                    }
                }
            } else {
                clb(FALSE,InstanceState_Unknown,@"Unable to process the stop of instance(s)");
            }
        });
    });
}

- (void)terminateInstance:(NSString*)instanceId clb:(dashStateClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 terminate-instances --instance-ids %@",instanceId]  checkError:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (output[@"TerminatingInstances"]) {
                for (NSDictionary * instance in output[@"TerminatingInstances"]) {
                    if (instance[@"InstanceId"] && instance[@"CurrentState"] && instance[@"CurrentState"][@"Name"]) {
                        [[DPDataStore sharedInstance] updateMasternode:instance[@"InstanceId"] withState:[self stateForStateName:instance[@"CurrentState"][@"Name"]]];
                        clb(TRUE,[self stateForStateName:instance[@"CurrentState"][@"Name"]],instance[@"InstanceId"]);
                    }
                }
            } else {
                clb(FALSE,InstanceState_Unknown,@"Unable to process the terminatation instance(s)");
            }
        });
    });
}

- (void)checkInstance:(NSString*)instanceId clb:(dashStateClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 describe-instances --filter Name=key-name,Values=%@",
                                                        [[PreferenceData sharedInstance] getKeyName]]  checkError:NO];
        NSArray * reservations = output[@"Reservations"];
        NSMutableArray * instances = [NSMutableArray array];
        for (NSDictionary * reservation in reservations) {
            //NSLog(@"%@",reservation[@"Instances"]);
            for (NSDictionary * dictionary in reservation[@"Instances"]) {
                NSDictionary * rDict = [NSMutableDictionary dictionary];
                [rDict setValue:[dictionary valueForKey:@"InstanceId"] forKey:@"instanceId"];
                [rDict setValue:[dictionary valueForKey:@"PublicIpAddress"] forKey:@"publicIP"];
                [rDict setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                [instances addObject:rDict];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray * newMasternodes = [self saveInstances:instances removeOthers:TRUE];
            for (NSManagedObject * masternode in newMasternodes) {
                [self checkMasternode:masternode];
            }
            clb(output?TRUE:FALSE,InstanceState_Unknown,@"Successfully refreshed");
        });
    });
}

- (void)createInstanceWithInitialAMI:(dashStateClb)clb serverType:(NSString*)serverType  {
    
    if (![self sshPath] || ![[PreferenceData sharedInstance] getKeyName]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"SSH_KEY.pem" exPath:@"~/Documents"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSArray *fileInfo = [dialog getSSHLaunchPathAndName];
            [self setSshPath:fileInfo[1]];
            
            NSArray* nameArray = [fileInfo[0] componentsSeparatedByString: @"."];
            NSString* nameString = [nameArray objectAtIndex: 0];
            
            [self setSshName:nameString];
        }
    }
    
    if([[PreferenceData sharedInstance] getSecurityGroupId]
       ||[[PreferenceData sharedInstance] getSubnetID]
       ||[[PreferenceData sharedInstance] getKeyName])
    {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            
            NSString *intialAMIID = @"ami-78d69092";
            
            NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 run-instances --image-id %@ --count 1 --instance-type %@ --key-name %@ --security-group-ids %@ --instance-initiated-shutdown-behavior terminate --subnet-id %@",
                                                            intialAMIID,
                                                            serverType,
                                                            [[PreferenceData sharedInstance] getKeyName],
                                                            [[PreferenceData sharedInstance] getSecurityGroupId],
                                                            [[PreferenceData sharedInstance] getSubnetID]]  checkError:NO];
            
            __block NSMutableDictionary * instances = [NSMutableDictionary dictionary];
            //NSLog(@"%@",reservation[@"Instances"]);
            for (NSDictionary * dictionary in output[@"Instances"]) {
                NSDictionary * rDict = [NSMutableDictionary dictionary];
                [rDict setValue:[dictionary valueForKey:@"InstanceId"] forKey:@"instanceId"];
                [rDict setValue:@(MasternodeState_Initial)  forKey:@"masternodeState"];
                [rDict setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                [instances setObject:rDict forKey:[dictionary valueForKey:@"InstanceId"]];
            }
            NSMutableArray * instanceIdsLeft = [[instances allKeys] mutableCopy];
            while ([instanceIdsLeft count]) {
                NSDictionary *output2 = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 describe-instances --instance-ids %@ --filter Name=key-name,Values=%@",[instanceIdsLeft componentsJoinedByString:@" "], [[PreferenceData sharedInstance] getKeyName]]  checkError:NO];
                NSArray * reservations = output2[@"Reservations"];
                for (NSDictionary * reservation in reservations) {
                    //NSLog(@"%@",reservation[@"Instances"]);
                    for (NSDictionary * dictionary in reservation[@"Instances"]) {
                        if ([dictionary valueForKey:@"PublicIpAddress"] && ![[dictionary valueForKeyPath:@"State.Name"] isEqualToString:@"pending"]) {
                            
                            [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[dictionary valueForKey:@"PublicIpAddress"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                if (sshSession.isAuthorized) {
                                    [[instances objectForKey:[dictionary valueForKey:@"InstanceId"]] setValue:[dictionary valueForKey:@"PublicIpAddress"] forKey:@"publicIP"];
                                    [[instances objectForKey:[dictionary valueForKey:@"InstanceId"]] setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                                    [instanceIdsLeft removeObject:[dictionary valueForKey:@"InstanceId"]];
                                    [sshSession disconnect];
                                }
                            }];
                        }
                    }
                }
                if (instanceIdsLeft) sleep(5);
            }
        });
        
    }
    else{
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create instance!" message:@"Please configure your AWS account in preference window."];
        
    }
    
}

-(InstanceState)stateForStateName:(NSString*)string {
    if ([string isEqualToString:@"running"]) {
        return InstanceState_Running;
    } else if ([string isEqualToString:@"pending"]) {
        return InstanceState_Pending;
    } else if ([string isEqualToString:@"stopped"]) {
        return InstanceState_Stopped;
    } else if ([string isEqualToString:@"terminated"]) {
        return InstanceState_Terminated;
    } else if ([string isEqualToString:@"stopping"]) {
        return InstanceState_Stopping;
    } else if ([string isEqualToString:@"rebooting"]) {
        return InstanceState_Rebooting;
    } else if ([string isEqualToString:@"shutting-down"]) {
        return InstanceState_Shutting_Down;
    } else if ([string isEqualToString:@"setting up"]) {
        return InstanceState_Setting_Up;
    }
    
    return InstanceState_Stopped;
}

-(NSArray*)saveInstances:(NSArray*)instances {
    return [self saveInstances:instances removeOthers:FALSE];
}

-(NSArray*)saveInstances:(NSArray*)instances removeOthers:(BOOL)removeOthers {
    NSDictionary * knownInstances = [[[DPDataStore sharedInstance] allMasternodes] dictionaryReferencedByKeyPath:@"instanceId"];
    NSDictionary * referencedInstances = [instances dictionaryReferencedByKeyPath:@"instanceId"];
    BOOL needsSave = FALSE;
    NSMutableArray * newMasternodes = [NSMutableArray array];
    for (NSString* reference in referencedInstances) {
        if ([knownInstances objectForKey:reference]) {
            if (![[[knownInstances objectForKey:reference] valueForKey:@"instanceState"] isEqualToNumber:[referencedInstances[reference] valueForKey:@"instanceState"]]) {
                needsSave = TRUE;
                [[knownInstances objectForKey:reference] setValue:[referencedInstances[reference] valueForKey:@"instanceState"] forKey:@"instanceState"];
                
            }
            if (![[[knownInstances objectForKey:reference] valueForKey:@"publicIP"] isEqualToString:[referencedInstances[reference] valueForKey:@"publicIP"]]) {
                needsSave = TRUE;
                [[knownInstances objectForKey:reference] setValue:[referencedInstances[reference] valueForKey:@"publicIP"] forKey:@"publicIP"];
            }
        } else {
            needsSave = TRUE;
            NSManagedObject * masternode = [[DPDataStore sharedInstance] addMasternode:referencedInstances[reference] saveContext:FALSE];
            [newMasternodes addObject:masternode];
        }
    }
    if (removeOthers) {
        for (NSString* knownInstance in knownInstances) {
            if (!referencedInstances[knownInstance]) {
                needsSave = TRUE;
                [[[DPDataStore sharedInstance] mainContext] deleteObject:knownInstances[knownInstance]];
            }
        }
    }
    if (needsSave) {
        [[DPDataStore sharedInstance] saveContext];
    }
    return newMasternodes;
}
                   


- (void)getInstancesClb:(dashClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 describe-instances --filter Name=key-name,Values=%@",
                                                        [[PreferenceData sharedInstance] getKeyName]]  checkError:NO];
        NSArray * reservations = output[@"Reservations"];
        NSMutableArray * instances = [NSMutableArray array];
        for (NSDictionary * reservation in reservations) {
            //NSLog(@"%@",reservation[@"Instances"]);
            for (NSDictionary * dictionary in reservation[@"Instances"]) {
                NSDictionary * rDict = [NSMutableDictionary dictionary];
                [rDict setValue:[dictionary valueForKey:@"InstanceId"] forKey:@"instanceId"];
                [rDict setValue:[dictionary valueForKey:@"PublicIpAddress"] forKey:@"publicIP"];
                [rDict setValue:@([self stateForStateName:[dictionary valueForKeyPath:@"State.Name"]]) forKey:@"instanceState"];
                [instances addObject:rDict];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray * newMasternodes = [self saveInstances:instances removeOthers:TRUE];
            for (NSManagedObject * masternode in newMasternodes) {
                [self checkMasternode:masternode];
            }
            if([newMasternodes count] == 0) {
                NSArray * checkingMasternodes = [[DPDataStore sharedInstance] allMasternodes];
                for (NSManagedObject * masternode in checkingMasternodes) {
                    [self checkMasternode:masternode];
                }
            }
            clb(output?TRUE:FALSE,@"Successfully refreshed");
        });
    });
}

#pragma mark - Util

-(NSString*)randomPassword:(NSUInteger)length {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString *s = [NSMutableString stringWithCapacity:20];
    for (NSUInteger i = 0U; i < length; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

-(NSString*)createConfigDashFileForMasternode:(NSManagedObject*)masternode {
    if (![masternode valueForKey:@"rpcPassword"]) {
        [masternode setValue:[self randomPassword:15] forKey:@"rpcPassword"];
        [[DPDataStore sharedInstance] saveContext];
    }
    // First we need to make a proper configuration file
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource: @"dash" ofType: @"conf"];
    NSString *configFileContents = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:NULL];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:MASTERNODE_PRIVATE_KEY_STRING withString:[masternode valueForKey:@"key"]];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:EXTERNAL_IP_STRING withString:[masternode valueForKey:@"publicIP"]];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PASSWORD_STRING withString:[masternode valueForKey:@"rpcPassword"]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/dash.conf",
                          cachesDirectory];
    //create content - four lines of text
    NSString *content = configFileContents;
    //save content to the documents directory
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
    return fileName;
}

-(NSString*)createSentinelConfFileForMasternode:(NSManagedObject*)masternode {
    
    NSString *chainNetwork = @"network=mainnet\n";
    if ([[masternode valueForKey:@"chainNetwork"] rangeOfString:@"testnet"].location != NSNotFound
        || [[masternode valueForKey:@"chainNetwork"] rangeOfString:@"devnet"].location != NSNotFound) {
        chainNetwork = @"network=testnet\n";
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/sentinel.conf",
                          documentsDirectory];
    //create content - four lines of text
    NSString *content = [NSString stringWithFormat:@"# specify path to dash.conf or leave blankult=mainnet)\n# default is the same as DashCore\n#dash_conf=/home/evan82/.dashcore/dash.conf\n\n# valid options are mainnet, testnet (default=mainnet)\n%@\n# database connection details\ndb_name=database/sentinel.db\ndb_driver=sqlite\n", chainNetwork];
    //save content to the documents directory
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
    return fileName;
}

- (void)registerProtxForLocal:(NSArray*)AllMasternodes {
    NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
//    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
//        chainNetwork = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999", chainNetwork];
//    }
//    else {
//        chainNetwork = [NSString stringWithFormat:@"-%@", chainNetwork];
//    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject *masternode in AllMasternodes)
        {
            if([[masternode valueForKey:@"isSelected"] integerValue] == 1) {
                [self registerProtxForLocal:[masternode valueForKey:@"publicIP"] localChain:chainNetwork onClb:^(BOOL success, NSString *message) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEvent:message];
                        [masternode setValue:@(0) forKey:@"isSelected"];
                    });
                }];
            }
        }
    });
}

- (void)registerProtxForLocal:(NSString*)publicIP localChain:(NSString*)localChain onClb:(dashClb)clb {
    
//    protx register yZJg3ocKiCEZEWgag7YgLhtQ9iYnEbu8J6 1000 54.169.150.160:12999 0 yhXupqeWSenszCCHyXLUsBB7fBjEqQ2ssz 0 0 0 yZJg3ocKiCEZEWgag7YgLhtQ9iYnEbu8J6
    __block NSString *chainNetwork = localChain;
    __block NSString *collateralAddress;
    __block NSString *ownerKeyAddr;
    
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getnewaddress" forChain:chainNetwork onClb:^(BOOL success, NSString *message) {
        if(success == YES) {
            collateralAddress = message;
        }
    }];
    
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:@"getnewaddress" forChain:chainNetwork onClb:^(BOOL success, NSString *message) {
        if(success == YES) {
            ownerKeyAddr = message;
        }
    }];
    
    if([collateralAddress length] == 0 || [ownerKeyAddr length] == 0) return clb(NO, [NSString stringWithFormat:@"REMOTE-%@: something went wrong with getnewaddress command", publicIP]);
    
    NSString *protxCommand = [NSString stringWithFormat:@"protx register %@ 1000 %@:12999 0 %@ 0 0 0 %@", collateralAddress, publicIP, ownerKeyAddr, collateralAddress];
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:protxCommand forChain:chainNetwork onClb:^(BOOL success, NSString *message) {
        clb(success, [NSString stringWithFormat:@"REMOTE-%@: %@", publicIP, message]);
    }];
}

- (void)setUpDevnet:(NSArray*)allMasternodes {
    
    __block NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
    __block NSString *chainNetworkNoPort = [[DPDataStore sharedInstance] chainNetwork];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        chainNetwork = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999", chainNetwork];
    }
    else {
        chainNetwork = [NSString stringWithFormat:@"-%@", chainNetwork];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        int countMN = 0;
        for(NSManagedObject *masternode in allMasternodes) {
            if([[masternode valueForKey:@"chainNetwork"] isEqualToString:chainNetworkNoPort]) countMN = countMN+1;
        }
        
//        if(countMN < 14) {
//            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"need atleast 14 remotes to start devnet"]];
//            return;
//        }
    
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"checking local sync status"]];
        __block NSString *localMNStatus = @"";
        NSString *fullCommand = [NSString stringWithFormat:@"%@ mnsync status",chainNetwork];
        [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:fullCommand checkError:NO onClb:^(BOOL success, NSDictionary *dictionary) {
            localMNStatus = [dictionary valueForKey:@"AssetName"];
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"sync status %@", localMNStatus]];
        }];
        
        if([localMNStatus isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Your mnsync status is finished, please configure your remotes."]];
        }
        else {
            //step 1 make dip0003 and bip147 status to be started
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"checking dip0003 and bip147 status, those status need to be active."]];
            __block BOOL isSucceed = NO;
            __block int countTries = 0;
            while (1) {
                NSString *fullCommand = [NSString stringWithFormat:@"%@ getblockchaininfo",chainNetwork];
                [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:fullCommand checkError:NO onClb:^(BOOL success, NSDictionary *dictionary) {
                    
                    countTries = countTries+1;
                    NSString *dip0003Status = [[[dictionary valueForKey:@"bip9_softforks"] valueForKey:@"dip0003"] valueForKey:@"status"];
                    NSString *bip147Status = [[[dictionary valueForKey:@"bip9_softforks"] valueForKey:@"bip147"] valueForKey:@"status"];
                    
                    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"dip0003: %@, bip147: %@", dip0003Status, bip147Status]];
                    
                    if([dip0003Status isEqualToString:@"active"] && [bip147Status isEqualToString:@"active"]) {
                        isSucceed = YES;
                    }
                    else {
                        [self generateBlock:chainNetwork numBlocks:@"100"];
                    }
                }];
                
                if(isSucceed == YES) {
                    break;
                }
                
//                if(countTries >= 30) {
//                    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Set up devnet failed. (error:1)"]];
//                    break;
//                }
//                sleep(5);
            }
            
            if(isSucceed == YES) {
                //step 2 configure remote
                [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Set up devnet successfully. Please configure your remotes by using 'Configure' button."]];
            }
            else {
                [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Set up devnet failed. (error:1)"]];
                return;
            }
        }
    });
}

- (void)generateBlock:(NSString*)chainNetwork numBlocks:(NSString*)blocks {
    NSString *fullCommand = [NSString stringWithFormat:@"generate %@ 100000000", blocks];
    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:fullCommand];
    [[DPLocalNodeController sharedInstance] runDashRPCCommandString:fullCommand forChain:chainNetwork onClb:^(BOOL success, NSString *message) {
//        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"%@", message]];
    }];
}

- (void)checkDevnetNetwork:(NSString*)chainName AllMasternodes:(NSArray*)allMasternodes {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        __block NSDictionary *localInfoDict = nil;
        [[DPLocalNodeController sharedInstance] runDashRPCCommandArray:[NSString stringWithFormat:@"-devnet=%@ -rpcport=12998 -port='12999 getinfo", chainName] checkError:NO onClb:^(BOOL success, NSDictionary *dictionary) {
            if(success == YES) {
                localInfoDict = dictionary;
            }
        }];
        
        if(localInfoDict == nil) {
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Please make sure your devnet name %@ is running.", chainName]];
            return;
        }
        
        NSString *chainNetwork = [NSString stringWithFormat:@"devnet=%@", chainName];
        BOOL devnetSucceed = YES;
        long blockHeight = [[localInfoDict valueForKey:@"blocks"] longValue];
        
        for(NSManagedObject *masternode in allMasternodes) {
            if([[masternode valueForKey:@"chainNetwork"] isEqualToString:chainNetwork]) {
                NSError *error;
                NSDictionary *remoteInfoDict = [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"getinfo" toMasternode:masternode error:&error];
                if(remoteInfoDict == nil) {
                    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Dashd server at %@ is not running.", [masternode valueForKey:@"publicIP"]]];
                    continue;
                }
                
                if([[remoteInfoDict valueForKey:@"blocks"] longValue] != [[localInfoDict valueForKey:@"blocks"] longValue]) {
                    [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"The block height between remote %@ (%@) and local (%@) are different", [masternode valueForKey:@"publicIP"], [remoteInfoDict valueForKey:@"blocks"], [localInfoDict valueForKey:@"blocks"]]];
                    devnetSucceed = NO;
                }
            }
        }
        
        if(devnetSucceed == YES) {
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"The network of devnet name %@ is working perfectly with the same block height at %ld.", chainName, blockHeight]];
        }
    });
}

#pragma mark - Block Control
- (void)validateMasternodeBlock:(NSArray*)masternodeObjects blockHash:(NSString*)blockHash clb:(dashClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject* masternode in masternodeObjects) {
            if([[masternode valueForKey:@"isSelected"] integerValue] == 1 ) {
                
                NSString *response = [[DPMasternodeController sharedInstance] sendRPCCommandString:[NSString stringWithFormat:@"invalidateblock %@", blockHash] toMasternode:masternode];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@(0) forKey:@"isSelected"];
                });
                response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], response];
                clb(YES, response);
            }
        }
    });
}

- (void)reconsiderMasternodeBlock:(NSArray*)masternodeObjects blockHash:(NSString*)blockHash clb:(dashClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject* masternode in masternodeObjects) {
            if([[masternode valueForKey:@"isSelected"] integerValue] == 1 ) {
                
                NSString *response = [[DPMasternodeController sharedInstance] sendRPCCommandString:[NSString stringWithFormat:@"reconsiderblock %@", blockHash] toMasternode:masternode];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@(0) forKey:@"isSelected"];
                });
                response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], response];
                clb(YES, response);
            }
        }
    });
}

- (void)clearBannedOnNodes:(NSArray*)masternodeObjects withCallback:(dashClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject* masternode in masternodeObjects) {
            if([[masternode valueForKey:@"isSelected"] integerValue] == 1 ) {
                
                NSString *response = [[DPMasternodeController sharedInstance] sendRPCCommandString:@"clearbanned" toMasternode:masternode];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@(0) forKey:@"isSelected"];
                });
                response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], response];
                clb(YES, response);
            }
        }
    });
}

- (void)getBlockchainInfoForNodes:(NSArray*)masternodeObjects clb:(dashClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(NSManagedObject* masternode in masternodeObjects) {
            if([[masternode valueForKey:@"isSelected"] integerValue] == 1 ) {
                
                NSString *response = [[DPMasternodeController sharedInstance] sendRPCCommandString:@"getblockchaininfo" toMasternode:masternode];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@(0) forKey:@"isSelected"];
                });
                response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], response];
                clb(YES, response);
            }
        }
    });
}

#pragma mark - Singleton methods

+ (DPMasternodeController *)sharedInstance
{
    static DPMasternodeController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPMasternodeController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}


@end
