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
#import "DPLocalNodeController.h"
#import "DashcoreStateTransformer.h"
#import "MasternodeSyncStatusTransformer.h"
//#import "DFSSHServer.h"
//#import "DFSSHConnector.h"
//#import "DFSSHOperator.h"
#import "DialogAlert.h"
#import "PreferenceData.h"
#import <NMSSH/NMSSH.h>
#import "SshConnection.h"
#import "Branch+CoreDataClass.h"
#import "Masternode+CoreDataClass.h"
#import "InsightStateTransformer.h"
#import "DAPIStateTransformer.h"
#import "DashDriveStateTransformer.h"
#import "SentinelStateTransformer.h"
#import "DPAuthenticationManager.h"

#define MASTERNODE_PRIVATE_KEY_STRING @"[MASTERNODE_PRIVATE_KEY]"
#define RPC_PASSWORD_STRING @"[RPC_PASSWORD]"
#define RPC_PORT_STRING @"[RPC_PORT]"
#define INSIGHT_PORT_STRING @"[INSIGHT_PORT]"
#define EXTERNAL_IP_STRING @"[EXTERNAL_IP]"

#define SPORK_ADDRESS_STRING @"[SPORK_ADDRESS]"
#define SPORK_PRIVATE_KEY_STRING @"[SPORK_PRIVATE_KEY]"
#define NETWORK_LINE @"[NETWORK_LINE]"

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

-(void)createBackgroundSSHSessionOnMasternode:(Masternode*)masternode clb:(dashSSHClb)clb {
    __block NSString * publicIP = masternode.publicIP;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            clb(success,message,sshSession);
            
        }];
    });
    
}

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
    if (![gitPath hasPrefix:@"~"]) {
        gitPath = [NSString stringWithFormat:@"~%@",gitPath];
    }
    [ssh.channel execute:[NSString stringWithFormat:@"cd %@", gitPath] error:&error];
    if (error) {
        NSLog(@"location not found! %@",error.localizedDescription);
        return nil;
    }
    
    NSMutableDictionary * rDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
    for (NSString * gitCommand in commands) {
        //   Run the 2nd command in the remote shell, which will be
        //   to "ls" the directory.
        error = nil;
        NSString *cmdOutput = [ssh.channel execute:[NSString stringWithFormat:@"cd %@; git %@", gitPath, gitCommand] error:&error];
        if (error) {
            NSLog(@"error trying to send git command! %@",error.localizedDescription);
            return nil;
        }
        else{
            
            NSString * returnString = cmdOutput;
            returnString = [returnString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [rDict setObject:cmdOutput forKey:gitCommand];
        }
    }
    
    return rDict;
}

-(NMSSHSession*)connectInstance:(Masternode*)masternode {
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

//-(void)sendDashCommandList:(NSArray*)commands onSSH:(NMSSHSession*)ssh error:(NSError**)error {
//    [self sendDashCommandList:commands onSSH:ssh commandExpectedLineCounts:nil error:error percentageClb:nil];
//}
//
//
//-(void)sendDashCommandList:(NSArray*)commands onSSH:(NMSSHSession*)ssh commandExpectedLineCounts:(NSArray*)expectedlineCounts error:(NSError**)error percentageClb:(dashPercentageClb)clb {
//    [self sendCommandList:commands toPath:@"~/src/dash" onSSH:ssh commandExpectedLineCounts:expectedlineCounts error:error percentageClb:clb];
//}
//
//-(void)sendCommandList:(NSArray*)commands toPath:(NSString*)path onSSH:(NMSSHSession*)ssh error:(NSError**)error {
//    [self sendCommandList:commands toPath:path onSSH:ssh commandExpectedLineCounts:nil error:error percentageClb:nil];
//}
//
//-(void)sendCommandList:(NSArray*)commands toPath:(NSString*)path onSSH:(NMSSHSession*)ssh commandExpectedLineCounts:(NSArray*)expectedlineCounts error:(NSError**)error percentageClb:(dashPercentageClb)clb {
//    //expected line counts are used to give back a percentage complete on this function;
//    
//    NSInteger channelNum = [[ssh QuickShell] integerValue];
//    if (channelNum < 0) {
//        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//    
//    //  This is the prompt we'll be expecting to find in
//    //  the output of the remote shell.
//    NSString *myPrompt = [NSString stringWithFormat:@":%@$",path];
//    //   Run the 1st command in the remote shell, which will be to
//    //   "cd" to a subdirectory.
//    BOOL success = [ssh ChannelSendString: @(channelNum) strData:[NSString stringWithFormat:@"cd %@\n",path] charset: @"ansi"];
//    if (success != YES) {
//        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
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
//        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
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
//        return;
//    };
//    NSMutableDictionary * rDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
//    for (NSUInteger index = 0;index<[commands count];index++) {
//        NSString * command = [commands objectAtIndex:index];
//        NSNumber * numberLines = ([expectedlineCounts count] > index)?[expectedlineCounts objectAtIndex:index]:nil;
//        //   Run the 2nd command in the remote shell, which will be
//        //   to "ls" the directory.
//        success = [ssh ChannelSendString: @(channelNum) strData:[NSString stringWithFormat:@"%@\n",command] charset: @"ansi"];
//        if (success != YES) {
//            *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//            NSLog(@"%@",ssh.LastErrorText);
//            return;
//        }
//        if (numberLines && [numberLines integerValue] > 1) {
//            NSMutableString * mOutput = [NSMutableString string];
//            while (1) {
//                NSNumber * poll = [ssh ChannelReadAndPoll: @(channelNum) pollTimeoutMs:@(3000)];
//                if ([poll integerValue] == -1) {
//                    *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//                    NSLog(@"%@",ssh.LastErrorText);
//                    return;
//                } else if ([poll integerValue] > 0) {
//                    [mOutput appendString:[ssh GetReceivedText: @(channelNum) charset: @"ansi"]];
//                    NSUInteger numberOfLines, index, stringLength = [mOutput length];
//                    
//                    for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
//                        index = NSMaxRange([mOutput lineRangeForRange:NSMakeRange(index, 0)]);
//                    clb(command,numberOfLines / [numberLines floatValue]);
//                }
//                if ([[mOutput stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] hasSuffix:myPrompt]) {
//                    clb(command,1.0);
//                    [rDict setObject:[mOutput copy] forKey:command];
//                    break;
//                }
//            }
//        } else {
//            //  Retrieve and display the output.
//            success = [ssh ChannelReceiveUntilMatch: @(channelNum) matchPattern: myPrompt charset: @"ansi" caseSensitive: YES];
//            if (success != YES) {
//                *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//                NSLog(@"%@",ssh.LastErrorText);
//                return;
//            }
//            clb(command,1.0);
//            cmdOutput = [ssh GetReceivedText: @(channelNum) charset: @"ansi"];
//            if (ssh.LastMethodSuccess != YES) {
//                *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//                NSLog(@"%@",ssh.LastErrorText);
//                return;
//            }
//            [rDict setObject:cmdOutput forKey:command];
//        }
//    }
//    
//    //  Send an EOF.  This tells the server that no more data will
//    //  be sent on this channel.  The channel remains open, and
//    //  the SSH client may still receive output on this channel.
//    success = [ssh ChannelSendEof: @(channelNum)];
//    if (success != YES) {
//        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//    
//    //  Close the channel:
//    success = [ssh ChannelSendClose: @(channelNum)];
//    if (success != YES) {
//        *error = [NSError errorWithDomain:@"org.quantumexplorer.dashplayground" code:0 userInfo:@{NSLocalizedDescriptionKey:ssh.LastErrorText}];
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//}
//
//-(NMSSHSession *)loginPrivateKeyAtPath:(NSString*)path {
//    CkoSshKey *key = [[CkoSshKey alloc] init];
//    
//    //  Read the PEM file into a string variable:
//    //  (This does not load the PEM file into the key.  The LoadText
//    //  method is a convenience method for loading the full contents of ANY text
//    //  file into a string variable.)
//    NSString *privKey = [key LoadText:path];
//    if (key.LastMethodSuccess != YES) {
//        NSLog(@"%@",key.LastErrorText);
//        return nil;
//    }
//    
//    //  Load a private key from a PEM string:
//    //  (Private keys may be loaded from OpenSSH and Putty formats.
//    //  Both encrypted and unencrypted private key file formats
//    //  are supported.  This example loads an unencrypted private
//    //  key in OpenSSH format.  PuTTY keys typically use the .ppk
//    //  file extension, while OpenSSH keys use the PEM format.
//    //  (For PuTTY keys, call FromPuttyPrivateKey instead.)
//    BOOL success = [key FromOpenSshPrivateKey: privKey];
//    if (success != YES) {
//        NSLog(@"%@",key.LastErrorText);
//        return nil;
//    }
//    return key;
//}
//
//-(NMSSHSession*)sftpIn:(NSString*)masternodeIP {
//    if (![self sshPath]) {
//        DialogAlert *dialog=[[DialogAlert alloc]init];
//        NSAlert *findPathAlert = [dialog getFindPathAlert:@"SSH_KEY.pem" exPath:@"~/Documents"];
//        
//        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
//            //Find clicked
//            NSString *pathString = [dialog getLaunchPath];
//            [self setSshPath:pathString];
//            return [self sftpIn:masternodeIP privateKeyPath:pathString];
//        }
//    }
//    else{
//        return [self sftpIn:masternodeIP privateKeyPath:[self sshPath]];
//    }
//    
//    return nil;
//}
//
//-(NMSSHSession*)sftpIn:(NSString*)masternodeIP privateKeyPath:(NSString*)privateKeyPath {
//    //  Important: It is helpful to send the contents of the
//    //  sftp.LastErrorText property when requesting support.
//    
//    CkoSFtp *sftp = [[CkoSFtp alloc] init];
//    
//    //  Any string automatically begins a fully-functional 30-day trial.
//    BOOL success = [sftp UnlockComponent: @"Anything for 30-day trial"];
//    if (success != YES) {
//        NSLog(@"%@",sftp.LastErrorText);
//        return nil;
//    }
//    
//    //  Set some timeouts, in milliseconds:
//    sftp.ConnectTimeoutMs = [NSNumber numberWithInt:15000];
//    sftp.IdleTimeoutMs = [NSNumber numberWithInt:15000];
//    
//    //  Connect to the SSH server.
//    //  The standard SSH port = 22
//    //  The hostname may be a hostname or IP address.
//    int port = 22;
//    NSString *hostname = masternodeIP;
//    success = [sftp Connect: hostname port: [NSNumber numberWithInt: port]];
//    if (success != YES) {
//        NSLog(@"%@",sftp.LastErrorText);
//        return nil;
//    }
//    
//    CkoSshKey * key = [self loginPrivateKeyAtPath:privateKeyPath];
//    if (!key) return nil;
//    //  Authenticate with the SSH server using the login and
//    //  private key.  (The corresponding public key should've
//    //  been installed on the SSH server beforehand.)
//    success = [sftp AuthenticatePk: @"ubuntu" privateKey: key];
//    if (success != YES) {
//        NSLog(@"%@",sftp.LastErrorText);
//        return nil;
//    }
//    NSLog(@"%@",@"Public-Key Authentication Successful!");
//    
//    //  After authenticating, the SFTP subsystem must be initialized:
//    success = [sftp InitializeSftp];
//    if (success != YES) {
//        NSLog(@"%@",sftp.LastErrorText);
//        return nil;
//    }
//    return sftp;
//}

- (void)setUpMainNode:(Masternode*)masternode clb:(dashActiveClb)clb {
    NSError *error;
    
    [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"mnsync status" toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary,NSString * errorMessage) {
        if(dictionary == nil || ![dictionary valueForKey:@"AssetName"]) {
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: the dash core server of main node is not started", [masternode valueForKey:@"publicIP"]]];
            clb(NO);
            return;
        }
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: mnsync status: %@", [masternode valueForKey:@"publicIP"], [dictionary valueForKey:@"AssetName"]]];
        if(![[dictionary valueForKey:@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:@"mnsync next"];
            [[DPMasternodeController sharedInstance] sendRPCCommandString:@"mnsync next" toMasternode:masternode clb:^(BOOL success, NSString *message) {
                if (success) {
                    [self setUpMainNode:masternode clb:clb];
                } else {
                    clb(NO);
                }
            }];
            
        }
        else {
            //generate 1 block to activate masternode synchronization.
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: executing command: generate 1", [masternode valueForKey:@"publicIP"]]];
            [[DPMasternodeController sharedInstance] sendRPCCommandString:@"generate 1" toMasternode:masternode clb:^(BOOL success, NSString *message) {
                if (success) {
                    clb(YES);
                }
            }];
        }
    }];
}

- (void)addNodeToLocal:(Masternode*)masternode clb:(dashMessageClb)clb {
    
    NSString *port = @"19998";
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        port = @"12999";
    }
    NSString *command = [NSString stringWithFormat:@"addnode %@:%@ add", [masternode valueForKey:@"publicIP"], port];
    
    NSString *response = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:command forChain:chainNetwork];
    clb(YES, response);
}

- (void)addNodeToRemote:(Masternode*)masternode toPublicIP:(NSString*)publicIP clb:(dashMessageClb)clb {
    NSString *port = @"19998";
    NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        port = @"12999";
    }
    
    NSError *error;
    [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"getinfo" toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
        if(dictionary == nil || ![dictionary valueForKey:@"blocks"]) {
            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: The dash core server is not started", [masternode valueForKey:@"publicIP"]]];
            return clb(NO,nil);
        }
    }];
    
    
    
    NSString *command = [NSString stringWithFormat:@"addnode %@:%@ add", publicIP, port];
    error = nil;
    [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:command toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
        if (error) {
            clb(NO,nil);
            return;
        }
        //generate 1 block to activate masternode synchronization.
        
        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"[REMOTE-%@]: executing command: generate 1", [masternode valueForKey:@"publicIP"]]];
        [[DPMasternodeController sharedInstance] sendRPCCommandString:@"generate 1" toMasternode:masternode clb:^(BOOL success, NSString *message) {
            if (success) {
                clb(YES, [NSString stringWithFormat:@"%@",dictionary]);
            } else {
                clb(NO, nil);
            }
        }];
        
    }];
    
}


- (void)setUpMasternodeDashd:(Masternode*)masternode clb:(dashMessageClb)clb
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
    //            if ([[masternode valueForKey:@"masternodeState"] integerValue] == DPDashcoreState_Initial) {
    //                [masternode setValue:@(DashcoreState_Installed) forKey:@"masternodeState"];
    //            }
    //            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
    //        });
    //    });
    
    
}

- (void)configureMasternodeSentinel:(NSArray*)AllMasternodes {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(Masternode *object in AllMasternodes)
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

- (void)setUpMasternodeConfiguration:(Masternode*)masternode onChainName:(NSString*)chainName clb:(dashSuccessInfo)clb {
    
    
    //    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: trying to start dashd on local...", [masternode valueForKey:@"instanceId"]];
    //    clb(YES,eventMsg);
    
    if (!masternode.key) {
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ masternode genkey", masternode.chainNetwork, masternode.instanceId];
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(YES,eventMsg,NO);
        });
        
        NSString * key = [[DPLocalNodeController sharedInstance] runDashRPCCommandString:[NSString stringWithFormat:@"-%@ masternode genkey", masternode.chainNetwork] forChain:masternode.chainNetwork];
        
        if ([key length] >= 51) {
            if([key length] > 51) key = [key substringToIndex:[key length] - 1];
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.key = key;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setUpMasternodeConfiguration:masternode onChainName:chainName clb:clb];
            });
        }
        else {
            return clb(FALSE,@"Error generating masternode key",NO);
        }
    }
    
    if (masternode.transactionId && masternode.transactionOutputIndex) {
        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configuring masternode configuration file...", masternode.instanceId];
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(YES,eventMsg,NO);
            [[DPLocalNodeController sharedInstance] updateMasternodeConfigurationFileForMasternode:masternode clb:^(BOOL success, NSString *message) {
                if (success) {
                    [self configureRemoteMasternode:masternode clb:^(BOOL success, NSString *message) {
                        if(!success) {
                            return clb(success,message,NO);
                        }
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configure masternode configuration file successfully. Please wait for updating dash.conf file...", [masternode valueForKey:@"instanceId"]];
                        [masternode.managedObjectContext performBlockAndWait:^{
                            masternode.dashcoreState |= DPDashcoreState_Configured;
                            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                        }];
                        
                        
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
        
        NSMutableArray * outputs = [[[DPLocalNodeController sharedInstance] outputs:masternode.chainNetwork] mutableCopy];
        
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
                        [self configureRemoteMasternode:masternode clb:^(BOOL success, NSString *message) {
                            if(success != YES) {
                                return clb(success,message,NO);
                            }
                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: configure masternode configuration file successfully. Please wait for updating dash.conf file...", [masternode valueForKey:@"instanceId"]];
                            [masternode.managedObjectContext performBlockAndWait:^{
                                masternode.dashcoreState |= DPDashcoreState_Configured;
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                            }];
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

-(void)startDashdOnRemote:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb {
    
    if(!masternode.chainNetwork) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: please configure this instance before starting it.", [masternode valueForKey:@"instanceId"]];
            messageClb(NO, eventMsg);
            clb(NO,NO);
        });
        return;
    }
    [self createBackgroundSSHSessionOnMasternode:masternode clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        if (!success || !sshSession.authorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                messageClb(NO,@"Could not SSH in");
                clb(NO,NO);
            });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: running dashd...", [masternode valueForKey:@"instanceId"]];
            messageClb(NO, eventMsg);
        });
        NSString *command;
        if ([masternode.chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
            command = [NSString stringWithFormat:@"cd ~/src/dash/src; ./dashd -devnet=%@ -rpcport=12998 -port=12999", [masternode.chainNetwork stringByReplacingOccurrencesOfString:@"devnet-" withString:@""]];
        }
        else {
            command = [NSString stringWithFormat:@"cd ~/src/dash/src; ./dashd"];
        }
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                messageClb(NO, message);
            });
            if(error) {
                NSLog(@"%@",[error localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], [error localizedDescription]];
                    messageClb(NO, eventMsg);
                    return;
                });
            }
            else {
                [masternode.managedObjectContext performBlockAndWait:^{
                    masternode.dashcoreState |= DPDashcoreState_Running;
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Dash Core server is starting...", [masternode valueForKey:@"instanceId"]];
                    messageClb(YES, eventMsg);
                });
            }
        }];
    }];
}

-(void)stopDashdOnRemote:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb {
    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ stop",masternode.instanceId, masternode.chainNetwork, masternode.publicIP, masternode.rpcPassword];
    messageClb(NO, eventMsg);
    
    [self sendRPCCommandString:@"stop" toMasternode:masternode clb:^(BOOL success, NSString *message) {
        if ([message hasPrefix:@"error: couldn't connect to server"] || [message hasPrefix:@"Dash Core server stopping"]) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.dashcoreState &= ~DPDashcoreState_Running;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
        }
    }];
    
}

- (void)setUpMasternodeSentinel:(Masternode*)masternode clb:(dashMessageClb)clb {
    
    //    [masternode setValue:@(SentinelState_Checking) forKey:@"sentinelState"];
    //    [[DPDataStore sharedInstance] saveContext];
    //
    //    __block NSString *localChain = [[DPDataStore sharedInstance] chainNetwork];
    //    __block NSString *chainNetwork = [masternode valueForKey:@"chainNetwork"];
    //
    //    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
    //        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
    //            if(success == YES) {
    //
    //                __block BOOL isContinue = true;
    //
    //                NSError *error = nil;
    //                NSString *command = @"sudo apt-get update";
    //
    //                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                    isContinue = success;
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        clb(isContinue, message);
    //                    });
    //                }];
    //                if(isContinue == NO) return;
    //
    //                command = @"sudo apt-get install -y git python-virtualenv";
    //
    //                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                    isContinue = success;
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        clb(isContinue, message);
    //                    });
    //                }];
    //                if(isContinue == NO) return;
    //
    //                [[SshConnection sharedInstance] sendDashGitCloneCommandForRepositoryPath:@"https://github.com/dashpay/sentinel.git" toDirectory:@"~/.dashcore/sentinel" onSSH:sshSession onBranch:@"develop" error:error dashClb:^(BOOL success, NSString *message) {
    //                    isContinue = success;
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        clb(isContinue, message);
    //                    });
    //                }];
    //                if(isContinue == NO) return;
    //
    //                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        clb(success, message);
    //                    });
    //                }];
    //
    //                command = @"cd ~/.dashcore/sentinel; virtualenv venv";
    //
    //                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                    isContinue = success;
    //                    if(success == NO){
    //                        dispatch_async(dispatch_get_main_queue(), ^{
    //                            clb(YES, message);
    //                        });
    //
    //                        //if failed try another command
    //                        NSString *command = @"cd ~/.dashcore/sentinel; sudo apt-get install -y virtualenv";
    //
    //                        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                            isContinue = success;
    //                            dispatch_async(dispatch_get_main_queue(), ^{
    //                                clb(isContinue, message);
    //                            });
    //                        }];
    //                    }
    //                    else {
    //                        dispatch_async(dispatch_get_main_queue(), ^{
    //                            clb(YES, message);
    //                        });
    //                    }
    //                }];
    //                if(isContinue == NO) return;
    //
    //                command = @"cd ~/.dashcore/sentinel; venv/bin/pip install -r requirements.txt";
    //
    //                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                    isContinue = success;
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        clb(isContinue, message);
    //                    });
    //                }];
    //                if(isContinue == NO) return;
    //
    //                //configure sentinel.conf
    //
    //
    //                //                test sentinel is alive and talking to the still sync'ing wallet
    //                //
    //                //                venv/bin/python bin/sentinel.py
    //                //
    //                //                You should see: "dashd not synced with network! Awaiting full sync before running Sentinel."
    //                //                This is exactly what we want to see at this stage
    //                command = @"cd ~/.dashcore/sentinel; venv/bin/python bin/sentinel.py";
    //
    //                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                    isContinue = success;
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        clb(isContinue, message);
    //                    });
    //                }];
    //                if(isContinue == NO) return;
    //
    //                [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:[masternode valueForKey:@"publicIP"] rpcPassword:[masternode valueForKey:@"rpcPassword"] forChain:chainNetwork clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
    //                    if (!success) {
    //                        dispatch_async(dispatch_get_main_queue(), ^{
    //                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
    //                            clb(NO,eventMsg);
    //                        });
    //                    } else {
    //                        if (dictionary) {
    //                            if ([dictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
    //                                dispatch_async(dispatch_get_main_queue(), ^{
    //                                    [masternode setValue:@([MasternodeSyncStatusTransformer typeForTypeName:dictionary[@"AssetName"]]) forKey:@"syncStatus"];
    //                                    [[DPDataStore sharedInstance] saveContext];
    //                                    [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
    //                                        if (!success) {
    //                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
    //                                            clb(NO,eventMsg);
    //                                        } else  if (value) {
    //                                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], dictionary];
    //                                            clb(YES,eventMsg);
    //                                        }
    //                                    }];
    //                                });
    //                            }
    //                            else {
    //                                dispatch_async(dispatch_get_main_queue(), ^{
    //                                    clb(NO,@"Sync in progress. Must wait until sync is complete to start Masternode.");
    //                                });
    //                            }
    //                        }
    //                    }
    //
    //                    NSString *command = @"echo \"$(echo '* * * * * cd /home/ubuntu/.dashcore/sentinel && ./venv/bin/python bin/sentinel.py 2>&1 >> sentinel-cron.log' ; crontab -l)\" | crontab -";
    //
    //                    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
    //                        isContinue = success;
    //                        dispatch_async(dispatch_get_main_queue(), ^{
    //                            clb(isContinue, message);
    //                        });
    //                    }];
    //                    if(isContinue == NO) return;
    //
    //                    dispatch_async(dispatch_get_main_queue(), ^{
    //                        [masternode setValue:@(SentinelState_Installed) forKey:@"sentinelState"];
    //                        [[DPDataStore sharedInstance] saveContext];
    //                    });
    //                }];
    //
    //
    //            }
    //            else {
    //                dispatch_async(dispatch_get_main_queue(), ^{
    //                    clb(NO, @"SSH: could not SSH in!");
    //                });
    //            }
    //        }];
    //    });
}

- (void)checkMasternodeSentinel:(Masternode*)masternode clb:(dashMessageClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(success == YES) {
                
                NSError *error = nil;
                NSString *command = @"cd ~/.dashcore/sentinel; venv/bin/python bin/sentinel.py";
                
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(success, message);
                    });
                }];
            }
        }];
    });
}

- (void)configureRemoteMasternode:(Masternode*)masternode clb:(dashMessageClb)clb {
    
    [self createDashcoreConfigFileForMasternode:masternode clb:^(BOOL success, NSString *localFilePath) {
        if (!success) {
            clb(success,@"Did not authenticate");
            return;
        }
        NSString *remoteFilePath = @"/home/ubuntu/.dashcore/dash.conf";
        
        [self createBackgroundSSHSessionOnMasternode:masternode clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore" onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                if(!success) {
                    [[SshConnection sharedInstance] sendExecuteCommand:@"mkdir .dashcore" onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                        [self uploadFileAtPath:localFilePath toRemotePath:remoteFilePath inSSHSession:sshSession clb:clb];
                    }];
                } else {
                    [self uploadFileAtPath:localFilePath toRemotePath:remoteFilePath inSSHSession:sshSession clb:clb];
                }
            }];
        }];
        
    }];
    
}

-(void)uploadFileAtPath:(NSString*)localFilePath toRemotePath:(NSString*)remoteFilePath inSSHSession:(NMSSHSession*)sshSession clb:(dashMessageClb)clb  {
    BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
    if (uploadSuccess != YES) {
        NSLog(@"%@",[[sshSession lastError] localizedDescription]);
        clb(NO, [[sshSession lastError] localizedDescription]);
    }
    else {
        clb(YES, nil);
    }
}

- (void)configureRemoteMasternodeSentinel:(Masternode*)masternode clb:(dashMessageClb)clb {
    
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

-(void)wipeDataOnRemote:(Masternode*)masternode onClb:(dashMessageClb)clb {
    if([masternode valueForKey:@"publicIP"] == nil) return;
    __block NSString * chainNetwork = [masternode valueForKey:@"chainNetwork"];
    if (!chainNetwork || [chainNetwork isEqualToString:@""]) return;
    chainNetwork = [chainNetwork stringByReplacingOccurrencesOfString:@"=" withString:@"-"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            
            if(success != YES) return;
            
            __block BOOL isSuccess = YES;
            NSError *error = nil;
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/.dashcore/%@",chainNetwork] onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                isSuccess = success;
            }];
            if(isSuccess != YES) return;
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"mv ~/.dashcore/%@/wallet.dat ~/.dashcore/%@/wallet",chainNetwork,chainNetwork] onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
            }];
            
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"cd ~/.dashcore/%@; (rm *.dat || true) && (rm *.log || true) && rm -rf blocks && rm -rf chainstate && rm -rf database && rm -rf evodb",chainNetwork] onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
            }];
            
            [[SshConnection sharedInstance] sendExecuteCommand:[NSString stringWithFormat:@"mv ~/.dashcore/%@/wallet ~/.dashcore/%@/wallet.dat",chainNetwork,chainNetwork] onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
            }];
        }];
    });
}


#pragma mark - Start Remote

- (void)startMasternodeOnRemote:(Masternode*)masternode localChain:(NSString*)localChain clb:(dashInfoClb)clb {
    
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
                    [masternode.managedObjectContext performBlockAndWait:^{
                        masternode.dashcoreState = DPDashcoreState_Running;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
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
            __block NSUInteger triesLeft = 5;
            while (triesLeft > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ mnsync status", [masternode valueForKey:@"instanceId"], chainNetwork, publicIP, rpcPassword];
                    clb(NO, nil, eventMsg);
                });
                
                [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:publicIP rpcPassword:rpcPassword forChain:chainNetwork clb:^(BOOL success, NSDictionary *mnsyncDictionary, NSString *errorMessage) {
                    if (!triesLeft) return;
                    triesLeft--;
                    if (!success || !mnsyncDictionary) {
                        if (!triesLeft) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error: could not retrieve server information! Make sure dashd on remote is actually started.", [masternode valueForKey:@"instanceId"]];
                                clb(FALSE, nil, eventMsg);
                            });
                            
                        } else {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error trying to start remote server. Dashd might not be started.", [masternode valueForKey:@"instanceId"]];
                                clb(FALSE, nil, eventMsg);
                            });
                        }
                    }
                    if (!success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error trying to start remote server. Dashd might not be started.", [masternode valueForKey:@"instanceId"]];
                            clb(FALSE, nil, eventMsg);
                        });
                        //                    break;
                    } else {
                        if (mnsyncDictionary) {
                            if (![previousSyncStatus isEqualToString:mnsyncDictionary[@"AssetName"]]) {
                                if ([mnsyncDictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:mnsyncDictionary[@"AssetName"]];
                                        [[DPDataStore sharedInstance] saveContext];
                                        [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                            if (!success) {
                                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                                clb(FALSE, mnsyncDictionary, eventMsg);
                                                clb(NO,mnsyncDictionary,errorMessage);
                                            } else  if (value) {
                                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@ \n start remote successfully.", [masternode valueForKey:@"instanceId"], mnsyncDictionary];
                                                clb(TRUE, mnsyncDictionary, eventMsg);
                                                clb(YES, mnsyncDictionary,nil);
                                            }
                                            else {
                                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                                clb(NO,nil,eventMsg);
                                            }
                                        }];
                                    });
                                    
                                }else if ([mnsyncDictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FAILED"]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:mnsyncDictionary[@"AssetName"]];
                                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], mnsyncDictionary];
                                        clb(FALSE, mnsyncDictionary, eventMsg);
                                        [[DPDataStore sharedInstance] saveContext];
                                    });
                                    
                                }else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:mnsyncDictionary[@"AssetName"]];
                                        [[DPDataStore sharedInstance] saveContext];
                                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: could not start this masternode. Mnsync status: %@", [masternode valueForKey:@"instanceId"], mnsyncDictionary[@"AssetName"]];
                                        clb(FALSE, mnsyncDictionary, eventMsg);
                                    });
                                    
                                }
                            }
                            else if ([mnsyncDictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_INITIAL"]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error: Sync in progress. Must wait until sync is complete to start Masternode.", [masternode valueForKey:@"instanceId"]];
                                    clb(FALSE, nil, eventMsg);
                                });
                                
                            }
                        }
                    }
                    
                    
                }];
                
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
            
            [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                
                
                
                if(!success || !sshSession.authorized) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(NO,nil,@"Could not SSH in");
                    });
                    return;
                }
                __block NSUInteger triesLeft = 5;
                while (triesLeft > 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: -%@ -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ mnsync status",[masternode valueForKey:@"instanceId"], chainNetwork, publicIP, rpcPassword];
                        clb(FALSE, nil, eventMsg);
                    });
                    
                    [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:publicIP rpcPassword:rpcPassword forChain:chainNetwork clb:^(BOOL success, NSDictionary *mnsyncDictionary, NSString *errorMessage) {
                        if (!triesLeft) return;
                        triesLeft--;
                        if (!success || !mnsyncDictionary) {
                            if (!triesLeft) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error: could not retrieve server information! Make sure dashd on remote is actually started.", [masternode valueForKey:@"instanceId"]];
                                    clb(FALSE, nil, eventMsg);
                                });
                                
                            } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: Error trying to start remote server. Dashd might not be started.", [masternode valueForKey:@"instanceId"]];
                                });
                            }
                        } else {
                            triesLeft = 0;
                            if (![previousSyncStatus isEqualToString:mnsyncDictionary[@"AssetName"]]) {
                                if ([mnsyncDictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FINISHED"]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:mnsyncDictionary[@"AssetName"]];
                                        [[DPDataStore sharedInstance] saveContext];
                                        [self startRemoteMasternode:masternode localChain:localChain clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                            if (!success) {
                                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                                clb(FALSE, nil, eventMsg);
                                                clb(FALSE, nil, errorMessage);
                                            } else if (value) {
                                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], mnsyncDictionary];
                                                clb(TRUE, nil, eventMsg);
                                            }
                                            else {
                                                NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], errorMessage];
                                                clb(NO,nil,eventMsg);
                                            }
                                        }];
                                    });
                                    
                                }else if ([mnsyncDictionary[@"AssetName"] isEqualToString:@"MASTERNODE_SYNC_FAILED"]) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:mnsyncDictionary[@"AssetName"]];
                                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: %@", [masternode valueForKey:@"instanceId"], mnsyncDictionary];
                                        clb(FALSE, mnsyncDictionary, eventMsg);
                                        [[DPDataStore sharedInstance] saveContext];
                                    });
                                    
                                }else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:mnsyncDictionary[@"AssetName"]];
                                        [[DPDataStore sharedInstance] saveContext];
                                        NSString *eventMsg = [NSString stringWithFormat:@"[instance-id: %@]: could not start this masternode.  Mnsync status: %@", [masternode valueForKey:@"instanceId"], mnsyncDictionary[@"AssetName"]];
                                        clb(FALSE, mnsyncDictionary, eventMsg);
                                    });
                                    
                                }
                            }
                        }
                    }];
                    
                    sleep(5);
                }
                
                
                
            }];
            
            //            [ssh Disconnect];
        });
    }
}

- (void)startRemoteMasternode:(Masternode*)masternode localChain:(NSString*)localChain clb:(dashBoolClb)clb {
    
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

-(void)sendRPCCommand:(NSString*)command toPublicIP:(NSString*)publicIP rpcPassword:(NSString*)rpcPassword forChain:(NSString*)chainNetwork clb:(dashDataClb)clb {
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
    [[DPLocalNodeController sharedInstance] runDashRPCCommand:fullCommand checkError:YES onClb:clb];
}

-(void)sendRPCCommand:(NSString*)command toMasternode:(Masternode*)masternode clb:(dashDataClb)clb {
    return [self sendRPCCommand:command toPublicIP:masternode.publicIP rpcPassword:masternode.rpcPassword forChain:masternode.chainNetwork clb:clb];
}

-(void)sendRPCCommandJSONDictionary:(NSString*)command toPublicIP:(NSString*)publicIP rpcPassword:(NSString*)rpcPassword
                           forChain:(NSString*)chainNetwork clb:(dashInfoClb)clb {
    [self sendRPCCommand:command toPublicIP:publicIP rpcPassword:rpcPassword forChain:chainNetwork clb:^(BOOL success, NSString *message, NSData *data) {
        NSError * error = nil;
        NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && dictionary) {
            clb(YES,dictionary,nil);
        } else {
            clb(NO,nil,[error localizedDescription]);
        }
    }];
    
}

-(void)sendRPCCommandJSONDictionary:(NSString*)command toMasternode:(Masternode*)masternode clb:(dashInfoClb)clb {
    [self sendRPCCommand:command toMasternode:masternode clb:^(BOOL success, NSString *message, NSData *data) {
        if (!success) {
            clb(NO,nil,message);
            return;
        }
        NSError * error = nil;
        NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && dictionary) {
            clb(YES,dictionary,nil);
        } else {
            clb(NO,nil,[error localizedDescription]);
        }
    }];
}

-(void)sendRPCCommandString:(NSString*)command toMasternode:(Masternode*)masternode clb:(dashMessageClb)clb {
    [self sendRPCCommand:command toMasternode:masternode clb:^(BOOL success, NSString *message, NSData *data) {
        clb(success,message);
    }];
}

-(void)getInfo:(Masternode*)masternode clb:(dashInfoClb)clb {
    __block NSString * publicIP = [masternode valueForKey:@"publicIP"];
    __block NSString * rpcPassword = [masternode valueForKey:@"rpcPassword"];
    __block NSString * chainNetwork = [masternode valueForKey:@"chainNetwork"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [self sendRPCCommandJSONDictionary:@"getinfo" toPublicIP:publicIP rpcPassword:rpcPassword forChain:chainNetwork clb:clb];
    });
}

#pragma mark - SSH Query Remote

-(void)updateGitInfoForMasternode:(Masternode*)masternode forProject:(DPRepositoryProject)project clb:(dashInfoClb)clb {
    
    __block NSString * publicIP = masternode.publicIP;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            
            
            
            if (!sshSession.isAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,nil,@"SSH: error authenticating with server.");
                });
                return;
            }
            NSString * path = [NSString stringWithFormat:@"~/src/%@",[ProjectTypeTransformer directoryForProject:project]];
            
            NSDictionary * gitValues = [self sendGitCommands:@[@"rev-parse --short HEAD",@"rev-parse --abbrev-ref HEAD",@"config --get remote.origin.url"] onSSH:sshSession onPath:path];
            [sshSession disconnect];
            if (!gitValues) {
                clb(NO,nil,[NSString stringWithFormat:@"%@ is not installed",path]);
            } else {
                __block NSString * remoteURLPath = gitValues[@"config --get remote.origin.url"];
                __block NSString * repositoryOwner;
                __block NSString * repositoryName;
                if ([remoteURLPath containsString:@"@"]) { //security issue, not so great
                    remoteURLPath = [[remoteURLPath componentsSeparatedByString:@"@"] lastObject];
                } else {
                    remoteURLPath = [remoteURLPath stringByReplacingOccurrencesOfString:@"https://" withString:@""];
                }
                remoteURLPath = [remoteURLPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                NSArray * pathComponents = [remoteURLPath pathComponents];
                
                repositoryOwner = [pathComponents objectAtIndex:1];
                repositoryName = [[pathComponents objectAtIndex:2] stringByDeletingPathExtension];
                remoteURLPath = [@"https://" stringByAppendingString:remoteURLPath];
                if (![remoteURLPath hasSuffix:@".git"]) {
                    remoteURLPath = [remoteURLPath stringByAppendingString:@".git"];
                }
                
                __block NSString * branchName = nil;
                if (gitValues[@"rev-parse --abbrev-ref HEAD"]) {
                    branchName = [gitValues[@"rev-parse --abbrev-ref HEAD"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                __block NSString * commit = nil;
                if (gitValues[@"rev-parse --short HEAD"]) {
                    commit = [gitValues[@"rev-parse --short HEAD"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                }
                [masternode.managedObjectContext performBlockAndWait:^{
                    Repository * repository = [[DPDataStore sharedInstance] repositoryNamed:repositoryName forOwner:repositoryOwner inProject:project onRepositoryURLPath:remoteURLPath inContext:masternode.managedObjectContext saveContext:NO];
                    switch (project) {
                        case DPRepositoryProject_Core:
                            masternode.coreBranch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                            masternode.coreGitCommitVersion = commit;
                            break;
                        case DPRepositoryProject_Dapi:
                        {
                            Branch * branch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                            masternode.dapiBranch = branch;
                            masternode.dapiGitCommitVersion = commit;
                            break;
                        }
                        case DPRepositoryProject_Drive:
                            masternode.driveBranch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                            masternode.driveGitCommitVersion = commit;
                            break;
                        case DPRepositoryProject_Insight:
                            masternode.insightBranch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                            masternode.insightGitCommitVersion = commit;
                            break;
                        case DPRepositoryProject_Sentinel:
                            masternode.sentinelBranch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                            masternode.sentinelGitCommitVersion = commit;
                            break;
                        default:
                            clb(NO,nil,@"Unknown project");
                            return;
                    }
                    
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    clb(YES,gitValues,nil);
                }];
            }
        }];
        
    });
}

#pragma mark - SSH in info

-(void)retrieveConfigurationInfoThroughSSH:(Masternode*)masternode clb:(dashInfoClb)clb {
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
                clb(NO,nil,@"Could not retrieve configuration file");
            });
            return;
        }
        NSString *versionOutput = [ssh.channel execute:@"./src/dash/src/dash-cli --version" error:&error];
        if(error) {
            NSLog(@"%@",[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO,nil,@"Could not retrieve version");
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
            if (versionOutput && [versionOutput containsString:@"-"]) {
                NSString * version = [[[versionOutput componentsSeparatedByString:@"-"] lastObject] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                [rDict setObject:version forKey:@"gitversion"];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                return clb(YES,rDict,nil);
            });
        }
    });
}

-(void)retrieveVersionInfoThroughSSH:(Masternode*)masternode clb:(dashInfoClb)clb {
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
        NSString *strOutput = [ssh.channel execute:@"./src/dash/src/dash-cli --version" error:&error];
        if(error) {
            NSLog(@"%@",[error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO,nil,@"Could not retrieve version");
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

- (void)checkMasternodeIsInstalled:(Masternode*)masternode clb:(dashBoolClb)clb {
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
    });
}


-(BOOL)checkMasternodeIsProperlyConfigured:(Masternode *)masternode {
    return TRUE;
}

-(void)checkMasternodeChainNetwork:(Masternode*)masternode clb:(dashMessageClb)clb {
    
    if([masternode valueForKey:@"publicIP"] == nil) return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            
            if(success != YES) {
                clb(NO,nil);
                return;
            }
            
            __block BOOL isSuccess = YES;
            NSError *error = nil;
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore" onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                isSuccess = success;
            }];
            if(isSuccess != YES) {
                clb(NO,nil);
                return;
            }
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/.dashcore && cat dash.conf" onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                isSuccess = success;
                if(success == YES && message != nil){
                    NSArray *dashConf = [message componentsSeparatedByString:@"\n"];
                    NSString *chainString = @"Unknown";
                    
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
                                chainString = [NSString stringWithFormat:@"devnet-%@",[netArray objectAtIndex:1]];
                            }
                            else {
                                chainString = @"devnet-none";
                            }
                            break;
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternode setValue:chainString forKey:@"chainNetwork"];
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                        clb(YES,nil);
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [masternode setValue:@"Unknown" forKey:@"chainNetwork"];
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                        clb(NO,nil);
                    });
                }
            }];
            if(isSuccess != YES) return;
        }];
    });
}

-(void)checkMasternodeIsProperlyInstalled:(Masternode*)masternode onSSH:(NMSSHSession*)ssh {
    [self checkMasternodeIsProperlyInstalled:masternode onSSH:ssh dashClb:^(BOOL success, NSString *message) {
        
    }];
}

-(void)checkMasternodeIsProperlyInstalled:(Masternode*)masternode onSSH:(NMSSHSession*)ssh dashClb:(dashMessageClb)clb {
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
            
            [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:ssh mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
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
                
                [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:ssh mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
                    NSLog(@"SSH-%@: %@", publicIP, message);
                    clb(success,message);
                    checkResult = success;
                }];
            }
            else {//yes
                //does this masternode execute ./make?
                NSString *response = [ssh.channel execute:@"ls ~/src/dash/src/dashd" error:&error];
                if(error || [response length] == 0) {//no
                    
                    [[SshConnection sharedInstance] sendExecuteCommand:@"cd ~/src/dash/; make --file=Makefile -j4 -l8" onSSH:ssh mainThread:NO dashClb:^(BOOL success, NSString *message,NSError * error) {
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
        
        
        [masternode.managedObjectContext performBlockAndWait:^{
            masternode.dashcoreState = checkResult?DPDashcoreState_Installed:DPDashcoreState_SettingUp;
            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
        }];
        
    });
}

-(void)updateMasternodeAttributes:(Masternode*)masternode clb:(dashMessageClb)clb {
    __block NSString *publicIP = masternode.publicIP;
    __block NSString *rpcPassword = masternode.rpcPassword;
    __block NSString *chainNetwork = masternode.chainNetwork;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if(success != YES) {
                clb(NO,nil);
                return;
            }
            
            //NSArray *gitCommand = [NSArray array];
            //            //check value "gitCommit
            //            gitCommand = [[NSArray alloc] initWithObjects:@"rev-parse --short HEAD", nil];
            //            NSDictionary * gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/src/dash"];
            //            dispatch_async(dispatch_get_main_queue(), ^{
            //                if(gitValues != nil) {
            //                    [masternode setValue:gitValues[@"rev-parse --short HEAD"] forKey:@"gitCommit"];
            //                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            //                }
            //                else {
            //                    [masternode setValue:@"" forKey:@"gitCommit"];
            //                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            //                }
            //            });
            //
            //            //check value "branch.name"
            //            gitCommand = [[NSArray alloc] initWithObjects:@"branch", nil];
            //            gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/src/dash"];
            //            if(gitValues != nil) {
            //                NSArray *gitBranchArray = [[gitValues objectForKey:@"branch"] componentsSeparatedByString:@"\n"];
            //                NSString *gitBranch = @"";
            //                for(NSString *elements in gitBranchArray) {
            //                    if ([elements rangeOfString:@"*"].location != NSNotFound) {
            //                        NSArray *branchArray = [elements componentsSeparatedByString:@" "];
            //                        if([branchArray count] >= 2) gitBranch = [branchArray objectAtIndex:1];
            //                    }
            //                }
            //                dispatch_async(dispatch_get_main_queue(), ^{
            //                    [masternode setValue:gitBranch forKey:@"gitBranch"];
            //                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            //                });
            //            }
            //            else {
            //                dispatch_async(dispatch_get_main_queue(), ^{
            //                    [masternode setValue:@"" forKey:@"gitBranch"];
            //                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            //                });
            //            }
            
            //check value "sentinelGitCommit"
            NSArray * gitCommand = [[NSArray alloc] initWithObjects:@"rev-parse --short HEAD", nil];
            NSDictionary * gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/.dashcore/sentinel"];
            if(gitValues != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    masternode.sentinelGitCommitVersion = gitValues[@"rev-parse --short HEAD"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    masternode.sentinelGitCommitVersion = nil;
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
                    masternode.sentinelBranch = nil;//[Branch branchWithRepository] <-Todo assign proper value
                    //[masternode setValue:gitBranch forKey:@"sentinelGitBranch"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    masternode.sentinelBranch = nil;
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                });
            }
            
            //check value "SyncState"
            
            [self sendRPCCommandJSONDictionary:@"mnsync status" toPublicIP:publicIP rpcPassword:rpcPassword forChain:chainNetwork clb:^(BOOL success, NSDictionary *syncStatusDictionary, NSString * errorMessage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    masternode.syncStatus = [MasternodeSyncStatusTransformer typeForTypeName:syncStatusDictionary[@"AssetName"]];
                    [[DPDataStore sharedInstance] saveContext];
                });
            }];
            
            //check value "repositoryUrl"
            gitCommand = [[NSArray alloc] initWithObjects:@"config --get remote.origin.url", nil];
            gitValues = [self sendGitCommands:gitCommand onSSH:sshSession onPath:@"/src/dash"];
            if(gitValues != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:[gitValues valueForKey:@"config --get remote.origin.url"] forKey:@"repositoryUrl"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    clb(YES,nil);
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [masternode setValue:@"" forKey:@"repositoryUrl"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    clb(YES,nil);
                });
            }
        }];
    });
}

-(void)checkMasternode:(Masternode*)masternode {
    if(![masternode valueForKey:@"publicIP"]) return;
    [self checkMasternodeChainNetwork:masternode clb:^(BOOL success, NSString *message) {
        if (success) {
            [self checkMasternode:masternode saveContext:TRUE clb:^(BOOL success, NSString *message) {
                if (success && masternode.dashcoreState == DPDashcoreState_Running) {
                    [self updateMasternodeAttributes:masternode clb:^(BOOL success, NSString *message) {
                        
                    }];
                }
            }];
        }
    }];
    
}

-(void)checkMasternode:(Masternode*)masternode saveContext:(BOOL)saveContext clb:(dashMessageClb)clb {
    //we are going to check if a masternode is running, configured, etc...
    //first let's check to see if we have access to rpc
    __block NSString * rpcPassword = masternode.rpcPassword;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        if (rpcPassword) {
            //we most likely have access to rpc, it's running
            [self getInfo:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
                if (dictionary) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        masternode.dashcoreState = DPDashcoreState_Running;
                        masternode.lastKnownHeight = [dictionary[@"blocks"] longLongValue];
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                        
                        clb(TRUE,nil);
                    });
                } else {
                    [self checkMasternodeIsInstalled:masternode clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                        if (value) {
                            NSDictionary * dictionary = [[DPLocalNodeController sharedInstance] masternodeInfoInMasternodeConfigurationFileForMasternode:masternode];
                            if (dictionary && [dictionary[@"publicIP"] isEqualToString:[masternode valueForKey:@"publicIP"]]) {
                                [masternode setValuesForKeysWithDictionary:dictionary];
                                masternode.dashcoreState = DPDashcoreState_Configured;
                                if ([masternode hasChanges]) {
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }
                                [self updateGitInfoForMasternode:masternode forProject:DPRepositoryProject_Dapi clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                    clb(success,errorMessage);
                                }];
                            } else {
                                if (masternode.dashcoreState != DPDashcoreState_Installed) {
                                    masternode.dashcoreState = DPDashcoreState_Installed;
                                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                }
                                [self updateGitInfoForMasternode:masternode forProject:DPRepositoryProject_Dapi clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                    clb(success,errorMessage);
                                }];
                            }
                        } else {
                            if (masternode.dashcoreState != DPDashcoreState_Initial) {
                                masternode.dashcoreState = DPDashcoreState_Initial;
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                clb(TRUE,nil);
                            }
                        }
                    }];
                }
            }];
        } else { //we don't have access to the rpc, let's ssh in and retrieve it.
            [self retrieveConfigurationInfoThroughSSH:masternode clb:^(BOOL success, NSDictionary *info, NSString *errorMessage) {
                if (info[@"gitversion"]) {
                    __block NSString * gitVersion = info[@"gitversion"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        masternode.coreGitCommitVersion = gitVersion;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    });
                }
                if (![info[@"externalip"] isEqualToString:[masternode valueForKey:@"publicIP"]]) {
                    //the masternode has never been configured
                    [self checkMasternodeIsInstalled:masternode clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                        if (value) {
                            if ([[masternode valueForKey:@"masternodeState"] integerValue] != DPDashcoreState_Installed) {
                                masternode.dashcoreState = DPDashcoreState_Installed;
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                            }
                            [self updateGitInfoForMasternode:masternode forProject:DPRepositoryProject_Dapi clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                clb(success,errorMessage);
                            }];
                        } else {
                            if ([[masternode valueForKey:@"masternodeState"] integerValue] != DPDashcoreState_Initial) {
                                masternode.dashcoreState = DPDashcoreState_Initial;
                                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                clb(TRUE,nil);
                            }
                        }
                    }];
                } else {
                    masternode.rpcPassword = info[@"rpcpassword"];
                    masternode.key = info[@"masternodeprivkey"];
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    [self getInfo:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString *errorMessage) {
                        if (dictionary) {
                            masternode.dashcoreState = DPDashcoreState_Running;
                            masternode.lastKnownHeight = [dictionary[@"blocks"] longLongValue];
                            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                            [self updateGitInfoForMasternode:masternode forProject:DPRepositoryProject_Dapi clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                clb(success,errorMessage);
                            }];
                        } else {
                            [self checkMasternodeIsInstalled:masternode clb:^(BOOL success, BOOL value, NSString *errorMessage) {
                                if (value) {
                                    NSDictionary * dictionary = [[DPLocalNodeController sharedInstance] masternodeInfoInMasternodeConfigurationFileForMasternode:masternode];
                                    if (dictionary && [dictionary[@"publicIP"] isEqualToString:[masternode valueForKey:@"publicIP"]]) {
                                        [masternode setValuesForKeysWithDictionary:dictionary];
                                        masternode.dashcoreState = DPDashcoreState_Configured;
                                    } else {
                                        masternode.dashcoreState = DPDashcoreState_Installed;
                                    }
                                    if ([masternode hasChanges]) {
                                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                    }
                                    [self updateGitInfoForMasternode:masternode forProject:DPRepositoryProject_Dapi clb:^(BOOL success, NSDictionary *object, NSString *errorMessage) {
                                        clb(success,errorMessage);
                                    }];
                                } else {
                                    if ([[masternode valueForKey:@"masternodeState"] integerValue] != DPDashcoreState_Initial) {
                                        masternode.dashcoreState = DPDashcoreState_Initial;
                                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                        clb(YES,nil);
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

- (BOOL)removeDatFilesFromMasternode:(Masternode*)masternode {
    
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
    
    return TRUE;
    
    
}

#pragma mark - Packages

-(NSArray *)requiredPackages {
    return @[@"npm"];
}

-(void)checkRequiredPackagesAreInstalledOnMasternode:(Masternode*)masternode withClb:(dashActionClb)clb {
    [self checkPackages:[self requiredPackages] areInstalledOnMasternode:masternode withClb:clb];
}

-(void)checkPackages:(NSArray*)packages areInstalledOnMasternode:(Masternode*)masternode withClb:(dashActionClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        [[SshConnection sharedInstance] sshInWithKeyPath:[self sshPath] masternodeIp:masternode.publicIP openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
            if (success && sshSession.isAuthorized) {
                [self checkPackages:packages areInstalledInSession:sshSession withClb:^(BOOL success, BOOL installed) {
                    if (success && installed) {
                        NSLog(@"Packages install on node %@",masternode.publicIP);
                    }
                    dispatch_async(dispatch_get_main_queue(),^{
                        clb(success,installed);
                    });
                }];
            } else {
                dispatch_async(dispatch_get_main_queue(),^{
                    clb(NO,NO);
                });
            }
        }];
    });
}

-(void)checkRequiredPackagesAreInstalledInSession:(NMSSHSession*)sshSession withClb:(dashActionClb)clb {
    [self checkPackages:[self requiredPackages] areInstalledInSession:sshSession withClb:clb];
}

-(void)checkPackages:(NSArray*)packages areInstalledInSession:(NMSSHSession*)sshSession withClb:(dashActionClb)clb {
    
    NSError * error = nil;
    NSString * command = [NSString stringWithFormat:@"sudo apt-get update; sudo apt-get install -y %@",[packages componentsJoinedByString:@" "]];
    [[SshConnection sharedInstance] sendDashCommandsList:@[command] onSSH:sshSession onPath:nil error:error dashClb:^(BOOL success, NSString *call) {
        clb(success,YES);
    }];
}

-(NSString*)dependencyStringForMasternode:(Masternode*)masternode {
    NSMutableArray * dependencies = [NSMutableArray array];
    if (!masternode.installedNVM) {
        [dependencies addObjectsFromArray:[self dependenciesForNVM]];
    }
    if (!masternode.installedPM2) {
        [dependencies addObjectsFromArray:[self dependenciesForPM2]];
    }
    return [dependencies componentsJoinedByString:@";"];
}

-(NSArray*)dependenciesForPM2 {
    return @[@"npm install pm2 -g"];
}

-(NSArray*)dependenciesForNVM {
    return @[@"curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash; export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\";nvm install 8;nvm alias default 8"];
}

-(void)installDependenciesForMasternode:(Masternode*)masternode inSession:(NMSSHSession*)sshSession withClb:(dashActionClb)clb {
    __block NSString * command;
    [masternode.managedObjectContext performBlockAndWait:^{
        command = [self dependencyStringForMasternode:masternode];
    }];
    if ([command isEqualToString:@""]) {
        clb(YES,YES);
    } else {
        [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError*error) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.installedNVM = TRUE;
                masternode.installedPM2 = TRUE;
                [[DPDataStore sharedInstance] saveContext];
            }];
            clb(success,YES);
        }];
    }
}

-(void)gitCloneProjectWithRepositoryPath:(NSString*)repositoryPath toDirectory:(NSString*)directory andSwitchToBranch:(NSString*)branchName inSSHSession:(NMSSHSession *)ssh  dashClb:(dashMessageClb)clb {
    
    __block NSString *command = [NSString stringWithFormat:@"git clone %@ %@;cd %@;git checkout %@;git reset --hard;git pull %@ %@",repositoryPath, directory,directory,branchName,repositoryPath,branchName];
    
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:ssh mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            if (!error.code) {
                //most likely just already existed
                clb(YES,message);
                return;
            }
            clb(NO,@"Error at cloning.");
            return;
        }
        clb(YES,message);
    }];
}

#pragma mark - Insight



#pragma mark - Insight

- (void)configureInsightOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate clb:(dashMessageClb)clb {
    if (!(masternode.insightState & DPInsightState_Cloned)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            clb(NO,@"Error: Insight needs to be cloned first");
        });
        return;
    }
    if (!forceUpdate && (masternode.insightState & DPInsightState_Configured)) {
        [self installInsightOnMasternode:masternode clb:clb];
        return; //we are already configured
    }
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(success == YES) {
                                                     NSString *localFilePath = [self createInsightConfigFileForMasternode:masternode];
                                                     NSString *remoteFilePath = @"/home/ubuntu/src/dashcore-node/dashcore-node.json";
                                                     
                                                     BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
                                                     if (uploadSuccess != YES) {
                                                         NSLog(@"%@",[[sshSession lastError] localizedDescription]);
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             clb(NO, [[sshSession lastError] localizedDescription]);
                                                         });
                                                     }
                                                     else {
                                                         [masternode.managedObjectContext performBlockAndWait:^{
                                                             masternode.insightState |= DPInsightState_Configured;
                                                             [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                                                         }];
                                                         [self installInsightOnMasternode:masternode inSSHSession:sshSession clb:clb];
                                                     }
                                                 }
                                             }];
}

- (void)installInsightOnMasternode:(Masternode*)masternode clb:(dashMessageClb)clb {
    if (!(masternode.insightState & DPInsightState_Configured)) {
        clb(NO,@"Error: Insight needs to be configured first");
        return;
    }
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         clb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                 }
                                                 [self installInsightOnMasternode:masternode inSSHSession:sshSession clb:clb];
                                             }];
}


- (void)installInsightOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)session clb:(dashMessageClb)clb {
    __block BOOL shouldBreak = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        if (!(masternode.insightState & DPInsightState_Configured)) {
            if ([NSThread isMainThread]) {
                clb(NO,@"Error: Insight needs to be configured first");
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    clb(NO,@"Error: Insight needs to be configured first");
                });
            }
            shouldBreak = TRUE;
        }
    }];
    if (shouldBreak) return;
    
    NSString * command = @"cat /home/ubuntu/src/dashcore-node/dashcore-node.json";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:session mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO, message);
            });
            return;
        }
        [masternode.managedObjectContext performBlockAndWait:^{
            masternode.insightState |= DPInsightState_Installed;
            [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
        }];
        //At this point lets send a query to check if it's running
        [self checkInsightIsRunningOnMasternode:masternode inSSHSession:session clb:clb];
    }];
}

-(void)checkInsightIsConfiguredOnMasternode:(Masternode*)masternode clb:(dashMessageClb)clb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         clb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                 }
                                                 [self checkInsightIsConfiguredOnMasternode:masternode inSSHSession:sshSession clb:clb];
                                             }];
}

- (void)checkInsightIsConfiguredOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession clb:(dashMessageClb)clb {
    
    NSString * command = @"cat /home/ubuntu/src/dashcore-node/dashcore-node.json";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO, message);
            });
            return;
        }
        NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];
        if (!dictionary) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO, message);
            });
            return;
        }
        dictionary = dictionary[@"servicesConfig"];
        dictionary = dictionary[@"dashd"];
        dictionary = dictionary[@"connect"][0];
        NSString * rpcPasswordInConfigFile = dictionary[@"rpcpassword"];
        __block NSString * masternodeRpcPassword;
        [masternode.managedObjectContext performBlockAndWait:^{
            masternodeRpcPassword = masternode.rpcPassword;
        }];
        if ([rpcPasswordInConfigFile isEqualToString:masternodeRpcPassword]) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.insightState |= DPInsightState_Configured;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            //At this point lets send a query to check if it's running
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(YES, message);
            });
        } else {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.insightState &= ~DPInsightState_Configured;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(YES, @"Error: rpc password of insight configuration does not match");
            });
        }
        
    }];
}

-(void)checkInsightIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActiveClb)clb messageClb:(dashMessageClb)messageClb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                 }
                                                 [self checkInsightIsRunningOnMasternode:masternode inSSHSession:sshSession clb:messageClb];
                                             }];
}

- (void)checkInsightIsRunningOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession clb:(dashMessageClb)clb {
    __block BOOL needConfigurationCheck = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        if (!(masternode.insightState & DPInsightState_Configured)) {
            needConfigurationCheck = YES;
        }
    }];
    if (needConfigurationCheck) {
        [self checkInsightIsConfiguredOnMasternode:masternode inSSHSession:sshSession clb:^(BOOL success, NSString *message) {
            if (success) {
                needConfigurationCheck = NO;
                [masternode.managedObjectContext performBlockAndWait:^{
                    if (!(masternode.insightState & DPInsightState_Configured)) {
                        needConfigurationCheck = YES;
                    }
                }];
                if (!needConfigurationCheck) {
                    [self checkInsightIsRunningOnMasternode:masternode inSSHSession:sshSession clb:clb];
                } else {
                    clb(success,message);
                }
            } else {
                clb(success,message);
            }
        }];
        return;
    }
    
    NSString * command = @"export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\";pm2 jlist";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO, message);
            });
            return;
        }
        NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSArray *pm2InfoArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];
        BOOL found = NO;
        for (NSDictionary * pm2InfoDictionary in pm2InfoArray) {
            if ([pm2InfoDictionary[@"name"] isEqualToString:@"dashcore-node"]) {
                NSDictionary * pm2Environment = pm2InfoDictionary[@"pm2_env"];
                if ([pm2Environment[@"status"] isEqualToString:@"online"]) {
                    [masternode.managedObjectContext performBlockAndWait:^{
                        masternode.insightState |= DPInsightState_Running;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
                    //At this point lets send a query to check if it's running
                    dispatch_async(dispatch_get_main_queue(), ^{
                        clb(YES, message);
                    });
                    found = TRUE;
                }
            }
        }
        if (!found) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.insightState &= ~DPInsightState_Running;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            //At this point lets send a query to check if it's running
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(YES, message);
            });
        }
    }];
}

#pragma mark - Dapi

- (void)configureDapiOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb  {
    if (!(masternode.dapiState & DPDapiState_Cloned)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionClb(NO,NO);
            messageClb(NO,@"Error: Dapi needs to be cloned first");
        });
        return;
    }
    if (!forceUpdate && (masternode.dapiState & DPDapiState_Configured)) {
        [self installDapiOnMasternode:masternode completionClb:completionClb messageClb:messageClb];
        return; //we are already configured
    }
    [self createBackgroundSSHSessionOnMasternode:masternode clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        if(success == YES) {
            NSString *localFilePath = [self createDapiEnvFileForMasternode:masternode];
            NSString *remoteFilePath = @"/home/ubuntu/src/dapi/.env";
            
            BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
            if (uploadSuccess != YES) {
                NSLog(@"%@",[[sshSession lastError] localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    messageClb(NO, @"Error: Error uploading dapi environment variables");
                });
            }
            else {
                [masternode.managedObjectContext performBlockAndWait:^{
                    masternode.dapiState |= DPDapiState_Configured;
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                }];
                [self installDapiOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
            }
        }
    }];
}

- (void)installDapiOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    if (!(masternode.dapiState & DPDapiState_Configured)) {
        completionClb(NO,NO);
        messageClb(NO,@"Error: Dapi needs to be configured first");
        return;
    }
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                 }
                                                 [self installDapiOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}


- (void)installDapiOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)session completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    __block BOOL shouldBreak = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        if (!(masternode.dapiState & DPDapiState_Configured)) {
            if ([NSThread isMainThread]) {
                messageClb(NO,@"Error: Dapi needs to be configured first");
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    messageClb(NO,@"Error: Dapi needs to be configured first");
                });
            }
            shouldBreak = TRUE;
        }
    }];
    if (shouldBreak) return;
    [[DPAuthenticationManager sharedInstance] authenticateNPMWithClb:^(BOOL authenticated, NSString *npmToken) {
        if (!authenticated || !npmToken || [npmToken isEqualToString:@""]) {
            messageClb(NO,@"Error: Dapi needs a npm token");
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                
                NSString * command = [NSString stringWithFormat:@"export NPM_TOKEN=\"%@\";export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\"; cd ~/src/dapi;echo \"//registry.npmjs.org/:_authToken=\\${NPM_TOKEN}\" > .npmrc; . ./.env; npm i; pm2 start index.js --name \"dapi\"; pm2 save",npmToken];
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:session mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
                    if(!success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            messageClb(NO, message);
                        });
                        return;
                    }
                    [masternode.managedObjectContext performBlockAndWait:^{
                        masternode.dapiState |= DPDapiState_Installed;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
                    //At this point lets send a query to check if it's running
                    [self checkDapiIsRunningOnMasternode:masternode inSSHSession:session completionClb:completionClb messageClb:messageClb];
                }];
            });
        }
    }];
    
}


-(void)checkDapiIsConfiguredOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         completionClb(NO,NO);
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                     return;
                                                 }
                                                 [self checkDapiIsConfiguredOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}

- (void)checkDapiIsConfiguredOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    
    NSString * command = @"cat /home/ubuntu/src/dapi/.env";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(NO,NO);
                messageClb(NO, message);
            });
            return;
        }
        NSArray * info = [message componentsSeparatedByString:@"\n"];
        NSString * rpcPasswordInConfigFile = nil;
        for (NSString * infoString in info) {
            if ([infoString containsString:@"DASHCORE_RPC_PASS"]) {
                rpcPasswordInConfigFile = [[infoString componentsSeparatedByString:@"="][1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        __block NSString * masternodeRpcPassword;
        [masternode.managedObjectContext performBlockAndWait:^{
            masternodeRpcPassword = masternode.rpcPassword;
        }];
        if ([rpcPasswordInConfigFile isEqualToString:masternodeRpcPassword]) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.dapiState |= DPDapiState_Configured;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            //At this point lets send a query to check if it's running
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,YES);
                messageClb(YES, message);
            });
        } else {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.dapiState &= ~DPDapiState_Configured;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,NO);
                messageClb(YES, @"Error: rpc password of dapi configuration does not match");
            });
        }
        
    }];
}


-(void)checkDapiIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         completionClb(NO,NO);
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                     return;
                                                 }
                                                 [self checkDapiIsRunningOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}

- (void)checkDapiIsRunningOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    __block BOOL needConfigurationCheck = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        if (!(masternode.dapiState & DPDapiState_Configured)) {
            needConfigurationCheck = YES;
        }
    }];
    if (needConfigurationCheck) {
        messageClb(NO,[NSString stringWithFormat:@"Info: Could not tell if DAPI is configured on %@, checking now.",sshSession.host]);
        [self checkDapiIsConfiguredOnMasternode:masternode inSSHSession:sshSession completionClb:^(BOOL success, BOOL configured) {
            if (success) {
                if (configured) {
                    [self checkDapiIsRunningOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                } else {
                    completionClb(YES,NO);
                }
            } else {
                completionClb(NO,NO);
            }
        } messageClb:messageClb];
        return;
    }
    
    NSString * command = @"export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\";pm2 jlist";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(NO,NO);
                messageClb(NO, message);
            });
            return;
        }
        NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSArray *pm2InfoArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];
        BOOL found = NO;
        for (NSDictionary * pm2InfoDictionary in pm2InfoArray) {
            if ([pm2InfoDictionary[@"name"] isEqualToString:@"dapi"]) {
                NSDictionary * pm2Environment = pm2InfoDictionary[@"pm2_env"];
                if ([pm2Environment[@"status"] isEqualToString:@"online"]) {
                    [masternode.managedObjectContext performBlockAndWait:^{
                        masternode.dapiState |= DPDapiState_Running;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
                    //At this point lets send a query to check if it's running
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionClb(YES,YES);
                        messageClb(YES, message);
                    });
                    found = TRUE;
                }
            }
        }
        if (!found) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.dapiState &= ~DPDapiState_Running;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            //At this point lets send a query to check if it's running
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,NO);
                messageClb(YES, message);
            });
        }
    }];
}

-(void)turnProjectInPM2:(DPRepositoryProject)project onOrOff:(BOOL)onOff onMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         completionClb(NO,NO);
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                     return;
                                                 }
                                                 [self turnProjectInPM2:project onOrOff:onOff onMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}

-(BOOL)projectNeedsConfigurationCheck:(DPRepositoryProject)project onMasternode:(Masternode*)masternode messageClb:(dashMessageClb)messageClb {
    __block BOOL needsConfigurationCheck = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        switch (project) {
            case DPRepositoryProject_Core:
                if (!(masternode.dashcoreState & DPDashcoreState_Installed)) {
                    needsConfigurationCheck = YES;
                }
                break;
            case DPRepositoryProject_Dapi:
                if (!(masternode.dapiState & DPDapiState_Installed)) {
                    needsConfigurationCheck = YES;
                }
                break;
            case DPRepositoryProject_Drive:
                if (!(masternode.driveState & DPDriveState_Installed)) {
                    needsConfigurationCheck = YES;
                }
                break;
            case DPRepositoryProject_Insight:
                if (!(masternode.insightState & DPInsightState_Installed)) {
                    needsConfigurationCheck = YES;
                }
                break;
            case DPRepositoryProject_Sentinel:
                if (!(masternode.sentinelState & DPSentinelState_Installed)) {
                    needsConfigurationCheck = YES;
                }
                break;
                
            default:
                break;
        }
        
    }];
    return needsConfigurationCheck;

}

- (void)turnProjectInPM2:(DPRepositoryProject)project onOrOff:(BOOL)onOff onMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    
//    if (needConfigurationCheck) {
//        messageClb(NO,[NSString stringWithFormat:@"Info: Could not tell if DAPI is configured on %@, checking now.",sshSession.host]);
//        [self checkDapiIsConfiguredOnMasternode:masternode inSSHSession:sshSession completionClb:^(BOOL success, BOOL configured) {
//            if (success) {
//                if (configured) {
//                    [self checkDapiIsRunningOnMasternode:masternode inSSHSession:sshSession completionClb:^(BOOL success, BOOL onStatus) {
//                        if (onStatus != onOff) {
//                            [self turnProjectInPM2:project onOrOff:onOff onMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
//                        }
//                    } messageClb:messageClb];
//                } else {
//                    completionClb(YES,NO);
//                }
//            } else {
//                completionClb(NO,NO);
//            }
//        } messageClb:messageClb];
//        return;
//    }
    NSString * pm2Command = @"";
    switch (project) {
        case DPRepositoryProject_Dapi:
            pm2Command = [NSString stringWithFormat:@"pm2 %@ dapi",onOff?@"start":@"stop"];
            break;
        case DPRepositoryProject_Drive:
            pm2Command = [NSString stringWithFormat:@"pm2 %@ drive-api;pm2 %@ drive-sync",onOff?@"start":@"stop",onOff?@"start":@"stop"];
            break;
        case DPRepositoryProject_Insight:
            pm2Command = [NSString stringWithFormat:@"pm2 %@ dashcore-node",onOff?@"start":@"stop"];
            break;
            
        default:
            break;
    }
    NSString * command = [NSString stringWithFormat:@"export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\";%@",pm2Command];
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(NO,NO);
                messageClb(NO, message);
            });
            return;
        }
        switch (project) {
            case DPRepositoryProject_Dapi:
                {
                    [masternode.managedObjectContext performBlockAndWait:^{
                        if (onOff) {
                            masternode.dapiState |= DPDapiState_Running;
                        } else {
                            masternode.dapiState &= ~DPDapiState_Running;
                        }
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
                }
                break;
            case DPRepositoryProject_Drive:
            {
                [masternode.managedObjectContext performBlockAndWait:^{
                    if (onOff) {
                        masternode.driveState |= DPDriveState_Running;
                    } else {
                        masternode.driveState &= ~DPDriveState_Running;
                    }
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                }];
            }
                break;
                
            default:
                break;
        }
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,NO);
                messageClb(YES, message);
            });
    }];
}


#pragma mark - Dash Drive

- (void)configureDriveOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb  {
    if (!(masternode.driveState & DPDriveState_Cloned)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionClb(NO,NO);
            messageClb(NO,@"Error: Drive needs to be cloned first");
        });
        return;
    }
    if (!forceUpdate && (masternode.driveState & DPDriveState_Configured)) {
        [self installDriveOnMasternode:masternode completionClb:completionClb messageClb:messageClb];
        return; //we are already configured
    }
    [self createBackgroundSSHSessionOnMasternode:masternode clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
        if(success == YES) {
            NSString *localFilePath = [self createDriveEnvFileForMasternode:masternode];
            NSString *remoteFilePath = @"/home/ubuntu/src/dashdrive/.env";
            
            BOOL uploadSuccess = [sshSession.channel uploadFile:localFilePath to:remoteFilePath];
            if (uploadSuccess != YES) {
                NSLog(@"%@",[[sshSession lastError] localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    messageClb(NO, @"Error: Error uploading drive environment variables");
                });
            }
            else {
                [masternode.managedObjectContext performBlockAndWait:^{
                    masternode.driveState |= DPDriveState_Configured;
                    [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                }];
                [self installDriveOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
            }
        }
    }];
}

- (void)installDriveOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    if (!(masternode.driveState & DPDriveState_Configured)) {
        completionClb(NO,NO);
        messageClb(NO,@"Error: Drive needs to be configured first");
        return;
    }
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                 }
                                                 [self installDriveOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}


- (void)installDriveOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)session completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    __block BOOL shouldBreak = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        if (!(masternode.driveState & DPDriveState_Configured)) {
            if ([NSThread isMainThread]) {
                messageClb(NO,@"Error: Drive needs to be configured first");
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    messageClb(NO,@"Error: Drive needs to be configured first");
                });
            }
            shouldBreak = TRUE;
        }
    }];
    if (shouldBreak) return;
    [[DPAuthenticationManager sharedInstance] authenticateNPMWithClb:^(BOOL authenticated, NSString *npmToken) {
        if (!authenticated || !npmToken || [npmToken isEqualToString:@""]) {
            messageClb(NO,@"Error: Drive needs a npm token");
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                
                NSString * command = [NSString stringWithFormat:@"sudo dpkg --configure -a; sudo apt-get update; sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common; curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"; sudo apt-get update; sudo apt-get install -y docker-ce; sudo curl -L \"https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose; sudo chmod +x /usr/local/bin/docker-compose; cd ~/src/dashdrive; sudo docker-compose up -d; export NPM_TOKEN=\"%@\"; export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\";echo \"//registry.npmjs.org/:_authToken=\\${NPM_TOKEN}\" > .npmrc; npm i; pm2 start scripts/api.js --name \"drive-api\"; pm2 start scripts/sync.js --name \"drive-sync\"; pm2 save",npmToken];
                [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:session mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
                    if(!success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            messageClb(NO, message);
                        });
                        return;
                    }
                    [masternode.managedObjectContext performBlockAndWait:^{
                        masternode.driveState |= DPDriveState_Installed;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
                    //At this point lets send a query to check if it's running
                    [self checkDriveIsRunningOnMasternode:masternode inSSHSession:session completionClb:completionClb messageClb:messageClb];
                }];
            });
        }
    }];
    
}


-(void)checkDriveIsConfiguredOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         completionClb(NO,NO);
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                     return;
                                                 }
                                                 [self checkDriveIsConfiguredOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}

- (void)checkDriveIsConfiguredOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    
    NSString * command = @"cat /home/ubuntu/src/dapi/.env";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(NO,NO);
                messageClb(NO, message);
            });
            return;
        }
        NSArray * info = [message componentsSeparatedByString:@"\n"];
        NSString * rpcPasswordInConfigFile = nil;
        for (NSString * infoString in info) {
            if ([infoString containsString:@"DASHCORE_RPC_PASS"]) {
                rpcPasswordInConfigFile = [[infoString componentsSeparatedByString:@"="][1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        __block NSString * masternodeRpcPassword;
        [masternode.managedObjectContext performBlockAndWait:^{
            masternodeRpcPassword = masternode.rpcPassword;
        }];
        if ([rpcPasswordInConfigFile isEqualToString:masternodeRpcPassword]) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.driveState |= DPDriveState_Configured;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            //At this point lets send a query to check if it's running
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,YES);
                messageClb(YES, message);
            });
        } else {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.driveState &= ~DPDriveState_Configured;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,NO);
                messageClb(YES, @"Error: rpc password of dapi configuration does not match");
            });
        }
        
    }];
}


-(void)checkDriveIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    [self createBackgroundSSHSessionOnMasternode:masternode
                                             clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                                                 
                                                 if(!success) {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         completionClb(NO,NO);
                                                         messageClb(NO,@"Error: Could not create SSH tunnel.");
                                                     });
                                                     return;
                                                 }
                                                 [self checkDriveIsRunningOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                                             }];
}

- (void)checkDriveIsRunningOnMasternode:(Masternode*)masternode inSSHSession:(NMSSHSession *)sshSession completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb {
    __block BOOL needConfigurationCheck = NO;
    [masternode.managedObjectContext performBlockAndWait:^{
        if (!(masternode.driveState & DPDriveState_Configured)) {
            needConfigurationCheck = YES;
        }
    }];
    if (needConfigurationCheck) {
        messageClb(NO,[NSString stringWithFormat:@"Info: Could not tell if DAPI is configured on %@, checking now.",sshSession.host]);
        [self checkDriveIsConfiguredOnMasternode:masternode inSSHSession:sshSession completionClb:^(BOOL success, BOOL configured) {
            if (success) {
                if (configured) {
                    [self checkDriveIsRunningOnMasternode:masternode inSSHSession:sshSession completionClb:completionClb messageClb:messageClb];
                } else {
                    completionClb(YES,NO);
                }
            } else {
                completionClb(NO,NO);
            }
        } messageClb:messageClb];
        return;
    }
    
    NSString * command = @"export NVM_DIR=\"$HOME/.nvm\";[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\";[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\";pm2 jlist";
    [[SshConnection sharedInstance] sendExecuteCommand:command onSSH:sshSession mainThread:NO dashClb:^(BOOL success, NSString *message,NSError *error) {
        if(!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(NO,NO);
                messageClb(NO, message);
            });
            return;
        }
        NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSArray *pm2InfoArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&jsonError];
        BOOL found = NO;
        for (NSDictionary * pm2InfoDictionary in pm2InfoArray) {
            if ([pm2InfoDictionary[@"name"] isEqualToString:@"dapi"]) {
                NSDictionary * pm2Environment = pm2InfoDictionary[@"pm2_env"];
                if ([pm2Environment[@"status"] isEqualToString:@"online"]) {
                    [masternode.managedObjectContext performBlockAndWait:^{
                        masternode.driveState |= DPDriveState_Running;
                        [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
                    }];
                    //At this point lets send a query to check if it's running
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completionClb(YES,YES);
                        messageClb(YES, message);
                    });
                    found = TRUE;
                }
            }
        }
        if (!found) {
            [masternode.managedObjectContext performBlockAndWait:^{
                masternode.driveState &= ~DPDriveState_Running;
                [[DPDataStore sharedInstance] saveContext:masternode.managedObjectContext];
            }];
            //At this point lets send a query to check if it's running
            dispatch_async(dispatch_get_main_queue(), ^{
                completionClb(YES,NO);
                messageClb(YES, message);
            });
        }
    }];
}

#pragma mark - Sentinel Checks


#pragma mark - Configuration File Creations

-(void)createDashcoreConfigFileForMasternode:(Masternode*)masternode clb:(dashMessageClb)clb {
    if (!masternode.rpcPassword) {
        masternode.rpcPassword = [self randomPassword:15];
        [[DPDataStore sharedInstance] saveContext];
    }
    [[DPAuthenticationManager sharedInstance] authenticateSporkWithClb:^(BOOL authenticated, NSString *address, NSString *privateKey) {
        if (!authenticated) {
            clb(NO,nil);
            return;
        }
        // First we need to make a proper configuration file
        NSString *configFilePath = [[NSBundle mainBundle] pathForResource: @"dash" ofType: @"conf"];
        NSString *configFileContents = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:NULL];
        configFileContents = [configFileContents stringByReplacingOccurrencesOfString:MASTERNODE_PRIVATE_KEY_STRING withString:masternode.key];
        configFileContents = [configFileContents stringByReplacingOccurrencesOfString:EXTERNAL_IP_STRING withString:masternode.publicIP];
        configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PASSWORD_STRING withString:masternode.rpcPassword];
        configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PORT_STRING withString:@"12998"];
        configFileContents = [configFileContents stringByReplacingOccurrencesOfString:SPORK_ADDRESS_STRING withString:address];
        configFileContents = [configFileContents stringByReplacingOccurrencesOfString:SPORK_PRIVATE_KEY_STRING withString:privateKey];
        if ([masternode.chainNetwork hasPrefix:@"devnet"]) {
            configFileContents = [configFileContents stringByReplacingOccurrencesOfString:NETWORK_LINE withString:[NSString stringWithFormat:@"devnet=%@",[masternode.chainNetwork stringByReplacingOccurrencesOfString:@"devnet-" withString:@""]]];
        } else {
            configFileContents = [configFileContents stringByReplacingOccurrencesOfString:NETWORK_LINE withString:@"testnet=1"];
        }
        
        
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
        clb(YES,fileName);
    }];
    
}

-(NSString*)createDapiEnvFileForMasternode:(Masternode*)masternode {
    if (!masternode.rpcPassword) {
        masternode.rpcPassword = [self randomPassword:15];
        [[DPDataStore sharedInstance] saveContext];
    }
    // First we need to make a proper configuration file
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"dapi" ofType:@"env"];
    NSString *configFileContents = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:NULL];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PASSWORD_STRING withString:[NSString stringWithFormat:@"\"%@\"",masternode.rpcPassword]];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PORT_STRING withString:@"12998"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/dapi.env",
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

-(NSString*)createDriveEnvFileForMasternode:(Masternode*)masternode {
    if (!masternode.rpcPassword) {
        masternode.rpcPassword = [self randomPassword:15];
        [[DPDataStore sharedInstance] saveContext];
    }
    // First we need to make a proper configuration file
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"drive" ofType:@"env"];
    NSString *configFileContents = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:NULL];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PASSWORD_STRING withString:[NSString stringWithFormat:@"\"%@\"",masternode.rpcPassword]];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PORT_STRING withString:@"12998"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/%@-drive.env",
                          cachesDirectory,masternode.instanceId];
    //create content - four lines of text
    NSString *content = configFileContents;
    //save content to the documents directory
    [content writeToFile:fileName
              atomically:NO
                encoding:NSStringEncodingConversionAllowLossy
                   error:nil];
    
    return fileName;
}

-(NSString*)createInsightConfigFileForMasternode:(Masternode*)masternode {
    if (!masternode.rpcPassword) {
        masternode.rpcPassword = [self randomPassword:15];
        [[DPDataStore sharedInstance] saveContext];
    }
    // First we need to make a proper configuration file
    NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"dashcore-node" ofType:@"json"];
    NSString *configFileContents = [NSString stringWithContentsOfFile:configFilePath encoding:NSUTF8StringEncoding error:NULL];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PASSWORD_STRING withString:[NSString stringWithFormat:@"\"%@\"",masternode.rpcPassword]];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:RPC_PORT_STRING withString:@"12998"];
    configFileContents = [configFileContents stringByReplacingOccurrencesOfString:INSIGHT_PORT_STRING withString:@"3001"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *fileName = [NSString stringWithFormat:@"%@/dashcore-node.json",
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

-(NSString*)createSentinelConfFileForMasternode:(Masternode*)masternode {
    
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

-(void)setUpInstances:(NSInteger)count onBranch:(Masternode*)branch clb:(dashInfoClb)clb onRegion:(NSMutableArray*)regionArray serverType:(NSString*)serverType {
    
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
                [rDict setValue:@(DPDashcoreState_Initial)  forKey:@"masternodeState"];
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
                for (Masternode * masternode in masternodes) {
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
            for (Masternode * masternode in newMasternodes) {
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
                [rDict setValue:@(DPDashcoreState_Initial)  forKey:@"masternodeState"];
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
            Masternode * masternode = [[DPDataStore sharedInstance] addMasternode:referencedInstances[reference] saveContext:FALSE];
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



- (void)getInstancesClb:(dashMessageClb)clb {
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
            for (Masternode * masternode in newMasternodes) {
                [self checkMasternode:masternode];
            }
            if([newMasternodes count] == 0) {
                NSArray * checkingMasternodes = [[DPDataStore sharedInstance] allMasternodes];
                for (Masternode * masternode in checkingMasternodes) {
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


#pragma mark - Devnet

- (void)registerProtxForLocal:(NSArray*)AllMasternodes {
    NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
    //    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
    //        chainNetwork = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999", chainNetwork];
    //    }
    //    else {
    //        chainNetwork = [NSString stringWithFormat:@"-%@", chainNetwork];
    //    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(Masternode *masternode in AllMasternodes)
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

- (void)registerProtxForLocal:(NSString*)publicIP localChain:(NSString*)localChain onClb:(dashMessageClb)clb {
    
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
        for(Masternode *masternode in allMasternodes) {
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
        
        NSString *chainNetwork = [NSString stringWithFormat:@"devnet-%@", chainName];
        __block BOOL devnetAlreadyFailed = NO;
        long blockHeight = [[localInfoDict valueForKey:@"blocks"] longValue];
        
        for(Masternode *masternode in allMasternodes) {
            if([[masternode valueForKey:@"chainNetwork"] isEqualToString:chainNetwork]) {
                [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"getinfo" toMasternode:masternode clb:^(BOOL success, NSDictionary *remoteInfoDict, NSString *errorMessage) {
                    if(!remoteInfoDict) {
                        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"Dashd server at %@ is not running.", [masternode valueForKey:@"publicIP"]]];
                        
                    } else if ([[remoteInfoDict valueForKey:@"blocks"] longValue] != [[localInfoDict valueForKey:@"blocks"] longValue]) {
                        [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"The block height between remote %@ (%@) and local (%@) are different", [masternode valueForKey:@"publicIP"], [remoteInfoDict valueForKey:@"blocks"], [localInfoDict valueForKey:@"blocks"]]];
                        
                        if (!devnetAlreadyFailed) {
                            [[[DPMasternodeController sharedInstance] masternodeViewController] addStringEventToMasternodeConsole:[NSString stringWithFormat:@"The network of devnet name %@ is working perfectly with the same block height at %ld.", chainName, blockHeight]];
                        }
                        devnetAlreadyFailed = YES;
                    }
                }];
                
            }
        }
    });
}

#pragma mark - Block Control
- (void)validateMasternodeBlock:(NSArray*)masternodeObjects blockHash:(NSString*)blockHash clb:(dashMessageClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(Masternode* masternode in masternodeObjects) {
            if(masternode.isSelected) {
                [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:[NSString stringWithFormat:@"invalidateblock %@", blockHash] toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString * errorMessage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        masternode.isSelected = NO;
                    });
                    NSString * response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], dictionary];
                    clb(YES, response);
                }];
                
            }
        }
    });
}

- (void)reconsiderMasternodeBlock:(NSArray*)masternodeObjects blockHash:(NSString*)blockHash clb:(dashMessageClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(Masternode* masternode in masternodeObjects) {
            if(masternode.isSelected) {
                
                [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:[NSString stringWithFormat:@"reconsiderblock %@", blockHash] toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString * errorMessage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        masternode.isSelected = NO;
                    });
                    NSString * response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], dictionary];
                    clb(YES, response);
                }];
            }
        }
    });
}

- (void)clearBannedOnNodes:(NSArray*)masternodeObjects withCallback:(dashMessageClb)clb {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(Masternode* masternode in masternodeObjects) {
            if(masternode.isSelected) {
                
                [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"clearbanned" toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString * errorMessage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        masternode.isSelected = NO;
                    });
                    NSString * response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], dictionary];
                    clb(YES, response);
                }];
            }
        }
    });
}

- (void)getBlockchainInfoForNodes:(NSArray*)masternodeObjects clb:(dashMessageClb)clb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        for(Masternode* masternode in masternodeObjects) {
            if(masternode.isSelected) {
                
                [[DPMasternodeController sharedInstance] sendRPCCommandJSONDictionary:@"getblockchaininfo" toMasternode:masternode clb:^(BOOL success, NSDictionary *dictionary, NSString * errorMessage) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        masternode.isSelected = NO;
                    });
                    NSString * response = [NSString stringWithFormat:@"%@: %@", [masternode valueForKey:@"publicIP"], dictionary];
                    clb(YES, response);
                }];
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
