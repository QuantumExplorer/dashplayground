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
//#import "DFSSHServer.h"
//#import "DFSSHConnector.h"
//#import "DFSSHOperator.h"

#define MASTERNODE_PRIVATE_KEY_STRING @"[MASTERNODE_PRIVATE_KEY]"
#define RPC_PASSWORD_STRING @"[RPC_PASSWORD]"
#define EXTERNAL_IP_STRING @"[EXTERNAL_IP]"

@interface DPMasternodeController ()


@end

@implementation DPMasternodeController

#pragma mark - Connectivity


-(NSString*)sendGitCommand:(NSString*)command onSSH:(CkoSsh *)ssh channelNum:(NSUInteger)channelNum {
    return [self sendCommandList:@[@"cd src/dash/\n",[NSString stringWithFormat:@"git %@",command]] onSSH:ssh channelNum:channelNum];
}


-(NSString*)sendCommandList:(NSArray*)commands onSSH:(CkoSsh *)ssh channelNum:(NSUInteger)channelNum {
    
    
    //  Construct a StringBuilder with multiple commands, one per line.
    //  Note: The line-endings are potentially important.  Some SSH servers may
    //  require either LF or CRLF line endings.  (Unix/Linux/OSX servers typically
    //  use bare-LF line endings.  Windows servers likely use CRLF line endings.)
    CkoStringBuilder *sbCommands = [[CkoStringBuilder alloc] init];
    for (NSString * command in commands) {
        [sbCommands Append:command];
    }
    
    //  For our last command, we're going to echo a marker string that
    //  we'll use in ChannelReceiveUntilMatch below.
    //  The use of single quotes around 'IS' is a trick so that the output
    //  of the command is "THIS IS THE END OF THE SCRIPT", but the terminal echo
    //  includes the single quotes.  This allows us to read until we see the actual
    //  output of the last command.
    [sbCommands Append: @"echo THIS 'IS' THE END OF THE SCRIPT\n"];
    
    //  Send the commands..
    BOOL success = [ssh ChannelSendString: @(channelNum) strData: [sbCommands GetAsString] charset: @"ansi"];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return nil;
    }
    //  Send an EOF to indicate no more commands will be sent.
    //  For brevity, we're not checking the return values of each method call.
    //  Your code should check the success/failure of each call.
    success = [ssh ChannelSendEof:@(channelNum)];
    
    //  Receive output up to our marker.
    success = [ssh ChannelReceiveUntilMatch:@(channelNum) matchPattern: @"THIS IS THE END OF THE SCRIPT" charset: @"ansi" caseSensitive: YES];
    
    //  Close the channel.
    //  It is important to close the channel only after receiving the desired output.
    success = [ssh ChannelSendClose:@(channelNum)];
    
    //  Get any remaining output..
    success = [ssh ChannelReceiveToClose:@(channelNum)];
    
    //  Get the complete output for all the commands in the session.
    NSLog(@"%@",@"--- output ----");
    return [ssh GetReceivedText:@(channelNum) charset: @"ansi"];
}

-(CkoSshKey *)loginPrivateKeyForMasternode:(NSManagedObject*)masternode {
    CkoSshKey *key = [[CkoSshKey alloc] init];
    
    //  Read the PEM file into a string variable:
    //  (This does not load the PEM file into the key.  The LoadText
    //  method is a convenience method for loading the full contents of ANY text
    //  file into a string variable.)
    NSString *privKey = [key LoadText: @"/Users/samuelw/Documents/SSH_KEY_DASH_PLAYGROUND.pem"];
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

-(CkoSFtp*)sftpIn:(NSManagedObject*)masternode {
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
    NSString *hostname = [masternode valueForKey:@"publicIP"];
    success = [sftp Connect: hostname port: [NSNumber numberWithInt: port]];
    if (success != YES) {
        NSLog(@"%@",sftp.LastErrorText);
        return nil;
    }
    
    CkoSshKey * key = [self loginPrivateKeyForMasternode:masternode];
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

-(CkoSsh*)sshIn:(NSManagedObject*)masternode channelNum:(NSUInteger *)channelNum {
    //  Important: It is helpful to send the contents of the
    //  sftp.LastErrorText property when sending email
    //  to support@chilkatsoft.com
    
    CkoSsh *ssh = [[CkoSsh alloc] init];
    
    //  Any string automatically begins a fully-functional 30-day trial.
    BOOL success = [ssh UnlockComponent: @"Anything for 30-day trial"];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return nil;
    }
    
    //  Set some timeouts, in milliseconds:
    ssh.ConnectTimeoutMs = [NSNumber numberWithInt:5000];
    ssh.IdleTimeoutMs = [NSNumber numberWithInt:15000];
    
    //  Connect to the SSH server.
    //  The standard SSH port = 22
    //  The hostname may be a hostname or IP address.
    int port;
    NSString *hostname = 0;
    hostname = [masternode valueForKey:@"publicIP"];
    port = 22;
    success = [ssh Connect: hostname port: [NSNumber numberWithInt: port]];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return nil;
    }
    CkoSshKey * key = [self loginPrivateKeyForMasternode:masternode];
    if (!key) return nil;
    //  Authenticate with the SSH server using the login and
    //  private key.  (The corresponding public key should've
    //  been installed on the SSH server beforehand.)
    success = [ssh AuthenticatePk: @"ubuntu" privateKey: key];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return nil;
    }
    NSLog(@"%@",@"Public-Key Authentication Successful!");
    
    //  Start a shell session.
    //  (The QuickShell method was added in Chilkat v9.5.0.65)
    *channelNum = [[ssh QuickShell] unsignedIntegerValue];
    if (channelNum < 0) {
        NSLog(@"%@",ssh.LastErrorText);
        return nil;
    }
    return ssh;
}

#pragma mark - Set Up

- (void)setUpMasternodeDashd:(NSManagedObject*)masternode
{
    NSUInteger channelNum = 0;
    CkoSsh * ssh = [self sshIn:masternode channelNum:&channelNum];
    if (!ssh) return;
    //  Send some commands and get the output.
    NSString *strOutput = [ssh QuickCommand: @"ls src | grep dash" charset: @"ansi"];
    if (ssh.LastMethodSuccess != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    BOOL justCloned = FALSE;
        if (![strOutput hasPrefix:@"dash"]) {
            justCloned = TRUE;
            [ssh QuickCommand: @"git clone https://github.com/QuantumExplorer/dash.git ~/src/dash" charset: @"ansi"];
            if (ssh.LastMethodSuccess != YES) {
                NSLog(@"%@",ssh.LastErrorText);
                return;
            }
        }
    if (!justCloned) {
        strOutput = [self sendCommandList:@[@"cd src/dash/\n",@"git pull\n"] onSSH:ssh channelNum:channelNum];
    }
    
    NSString * commitHash = [self sendGitCommand:@"rev-parse HEAD" onSSH:ssh channelNum:channelNum];
    NSLog(@"%@",strOutput);
    
    [ssh Disconnect];
    
    return;
}

- (void)configureMasternode:(NSManagedObject*)masternode {
    
    NSString *localFilePath = [self createConfigDashFileForMasternode:masternode];
    
    CkoSFtp * sftp = [self sftpIn:masternode];
    if (!sftp) return;
    
    //  Upload from the local file to the SSH server.
    //  Important -- the remote filepath is the 1st argument,
    //  the local filepath is the 2nd argument;
    NSString *remoteFilePath = @"/home/ubuntu/.dashcore/dash.conf";
    
    BOOL success = [sftp UploadFileByName: remoteFilePath localFilePath: localFilePath];
    if (success != YES) {
        NSLog(@"%@",sftp.LastErrorText);
        return;
    }
    
    NSLog(@"%@",@"Success.");
}


#pragma mark - Query Remote

-(NSData *)sendRPCCommand:(NSString*)command toMasternode:(NSManagedObject*)masternode {
    NSString * fullCommand = [NSString stringWithFormat:@"-testnet -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ %@",[masternode valueForKey:@"publicIP"],[masternode valueForKey:@"rpcPassword"], command];
    return [[DPLocalNodeController sharedInstance] runDashRPCCommand:fullCommand];
}

-(NSString *)sendRPCCommandString:(NSString*)command toMasternode:(NSManagedObject*)masternode {
    NSString * fullCommand = [NSString stringWithFormat:@"-testnet -rpcconnect=%@ -rpcuser=dash -rpcpassword=%@ %@",[masternode valueForKey:@"publicIP"],[masternode valueForKey:@"rpcPassword"], command];
    return [[DPLocalNodeController sharedInstance] runDashRPCCommandString:fullCommand];
}


#pragma mark - AWS Core

- (NSString *)runAWSCommandString:(NSString *)commandToRun
{
    
    NSString *output = [[NSString alloc] initWithData:[self runAWSCommand:commandToRun] encoding:NSUTF8StringEncoding];
    return output;
}

- (NSDictionary *)runAWSCommandJSON:(NSString *)commandToRun
{
    NSData * data = [self runAWSCommand:commandToRun];
    NSError * error = nil;
    NSDictionary *output = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &error];
    return output;
}

- (NSData *)runAWSCommand:(NSString *)commandToRun
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/local/bin/aws"];
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    return [file readDataToEndOfFile];
}

#pragma mark - Instances

- (void)runInstances:(NSInteger)count {
    NSString *output = [self runAWSCommandString:[NSString stringWithFormat:@"ec2 run-instances --image-id ami-889c0de8 --count %ld --instance-type t2.micro --key-name SSH_KEY_DASH_PLAYGROUND --security-group-ids sg-8a11f5f1 --instance-initiated-shutdown-behavior terminate --subnet-id subnet-b764acd2",(long)count]];
    NSLog(@"%@",output);
}

- (void)startInstance:(NSString*)instanceId {
    NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 start-instances --instance-ids %@",instanceId]];
    if (output[@"StartingInstances"]) {
        for (NSDictionary * instance in output[@"StartingInstances"]) {
            if (instance[@"InstanceId"] && instance[@"CurrentState"] && instance[@"CurrentState"][@"Name"]) {
                [[DPDataStore sharedInstance] updateMasternode:instance[@"InstanceId"] withState:[self stateForStateName:instance[@"CurrentState"][@"Name"]]];
            }
        }
    }
    NSLog(@"%@",output);
}

- (void)stopInstance:(NSString*)instanceId {
    NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 stop-instances --instance-ids %@",instanceId]];
    if (output[@"StoppingInstances"]) {
        for (NSDictionary * instance in output[@"StoppingInstances"]) {
            if (instance[@"InstanceId"] && instance[@"CurrentState"] && instance[@"CurrentState"][@"Name"]) {
                [[DPDataStore sharedInstance] updateMasternode:instance[@"InstanceId"] withState:[self stateForStateName:instance[@"CurrentState"][@"Name"]]];
            }
        }
    }
    NSLog(@"%@",output);
}

- (void)terminateInstance:(NSString*)instanceId {
    NSDictionary *output = [self runAWSCommandJSON:[NSString stringWithFormat:@"ec2 terminate-instances --instance-ids %@",instanceId]];
    if (output[@"TerminatingInstances"]) {
        for (NSDictionary * instance in output[@"TerminatingInstances"]) {
            if (instance[@"InstanceId"] && instance[@"CurrentState"] && instance[@"CurrentState"][@"Name"]) {
                [[DPDataStore sharedInstance] updateMasternode:instance[@"InstanceId"] withState:[self stateForStateName:instance[@"CurrentState"][@"Name"]]];
            }
        }
    }
    NSLog(@"%@",output);
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
    }
    
    return InstanceState_Stopped;
}

-(void)getInstances {
    NSDictionary *output = [self runAWSCommandJSON:@"ec2 describe-instances --filter Name=key-name,Values=SSH_KEY_DASH_PLAYGROUND"];
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
    NSDictionary * knownInstances = [[[DPDataStore sharedInstance] allMasternodes] dictionaryReferencedByKeyPath:@"instanceId"];
    
    NSDictionary * referencedInstances = [instances dictionaryReferencedByKeyPath:@"instanceId"];
    BOOL needsSave = FALSE;
    for (NSString* reference in referencedInstances) {
        if ([knownInstances objectForKey:reference]) {
            if (![[[knownInstances objectForKey:reference] valueForKey:@"instanceState"] isEqualToNumber:[referencedInstances[reference] valueForKey:@"instanceState"]]) {
                needsSave = TRUE;
            [[knownInstances objectForKey:reference] setValue:[referencedInstances[reference] valueForKey:@"instanceState"] forKey:@"instanceState"];
            }
        } else {
        needsSave = TRUE;
            [referencedInstances[reference] setValue:@(MasternodeState_Checking) forKey:@"masternodeState"];
        [[DPDataStore sharedInstance] addMasternode:referencedInstances[reference] saveContext:FALSE];
        }
    }
    for (NSString* knownInstance in knownInstances) {
        if (!referencedInstances[knownInstance]) {
            needsSave = TRUE;
            [[[DPDataStore sharedInstance] mainContext] deleteObject:knownInstances[knownInstance]];
        }
    }
    if (needsSave) {
        [[DPDataStore sharedInstance] saveContext];
    }
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
