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
#import "CkoSsh.h"
#import "CkoSshKey.h"
#import "CkoStringBuilder.h"
//#import "DFSSHServer.h"
//#import "DFSSHConnector.h"
//#import "DFSSHOperator.h"

@interface DPMasternodeController ()

@end

@implementation DPMasternodeController






- (NSData *)runCommand:(NSString *)commandToRun
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

- (void)sshIn:(NSString*)ip
{
    //  Important: It is helpful to send the contents of the
    //  sftp.LastErrorText property when sending email
    //  to support@chilkatsoft.com
    
    CkoSsh *ssh = [[CkoSsh alloc] init];
    
    //  Any string automatically begins a fully-functional 30-day trial.
    BOOL success = [ssh UnlockComponent: @"Anything for 30-day trial"];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //  Set some timeouts, in milliseconds:
    ssh.ConnectTimeoutMs = [NSNumber numberWithInt:5000];
    ssh.IdleTimeoutMs = [NSNumber numberWithInt:15000];
    
    //  Connect to the SSH server.
    //  The standard SSH port = 22
    //  The hostname may be a hostname or IP address.
    int port;
    NSString *hostname = 0;
    hostname = ip;
    port = 22;
    success = [ssh Connect: hostname port: [NSNumber numberWithInt: port]];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    CkoSshKey *key = [[CkoSshKey alloc] init];
    
    //  Read the PEM file into a string variable:
    //  (This does not load the PEM file into the key.  The LoadText
    //  method is a convenience method for loading the full contents of ANY text
    //  file into a string variable.)
    NSString *privKey = [key LoadText: @"/Users/samuelw/Documents/SSH_KEY_DASH_PLAYGROUND.pem"];
    if (key.LastMethodSuccess != YES) {
        NSLog(@"%@",key.LastErrorText);
        return;
    }
    
    //  Load a private key from a PEM string:
    //  (Private keys may be loaded from OpenSSH and Putty formats.
    //  Both encrypted and unencrypted private key file formats
    //  are supported.  This example loads an unencrypted private
    //  key in OpenSSH format.  PuTTY keys typically use the .ppk
    //  file extension, while OpenSSH keys use the PEM format.
    //  (For PuTTY keys, call FromPuttyPrivateKey instead.)
    success = [key FromOpenSshPrivateKey: privKey];
    if (success != YES) {
        NSLog(@"%@",key.LastErrorText);
        return;
    }
    
    //  Authenticate with the SSH server using the login and
    //  private key.  (The corresponding public key should've
    //  been installed on the SSH server beforehand.)
    success = [ssh AuthenticatePk: @"ubuntu" privateKey: key];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    NSLog(@"%@",@"Public-Key Authentication Successful!");
    
    //  Start a shell session.
    //  (The QuickShell method was added in Chilkat v9.5.0.65)
    int channelNum = [[ssh QuickShell] intValue];
    if (channelNum < 0) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //  Construct a StringBuilder with multiple commands, one per line.
    //  Note: The line-endings are potentially important.  Some SSH servers may
    //  require either LF or CRLF line endings.  (Unix/Linux/OSX servers typically
    //  use bare-LF line endings.  Windows servers likely use CRLF line endings.)
    CkoStringBuilder *sbCommands = [[CkoStringBuilder alloc] init];
    [sbCommands Append: @"ls\n"];
    [sbCommands Append: @"cd src\n"];
    [sbCommands Append: @"ls\n"];
    [sbCommands Append: @"df\n"];
    
    //  For our last command, we're going to echo a marker string that
    //  we'll use in ChannelReceiveUntilMatch below.
    //  The use of single quotes around 'IS' is a trick so that the output
    //  of the command is "THIS IS THE END OF THE SCRIPT", but the terminal echo
    //  includes the single quotes.  This allows us to read until we see the actual
    //  output of the last command.
    [sbCommands Append: @"echo THIS 'IS' THE END OF THE SCRIPT\n"];
    
    //  Send the commands..
    success = [ssh ChannelSendString: [NSNumber numberWithInt: channelNum] strData: [sbCommands GetAsString] charset: @"ansi"];
    if (success != YES) {
        NSLog(@"%@",ssh.LastErrorText);
        return;
    }
    
    //  Send an EOF to indicate no more commands will be sent.
    //  For brevity, we're not checking the return values of each method call.
    //  Your code should check the success/failure of each call.
    success = [ssh ChannelSendEof: [NSNumber numberWithInt: channelNum]];
    
    //  Receive output up to our marker.
    success = [ssh ChannelReceiveUntilMatch: [NSNumber numberWithInt: channelNum] matchPattern: @"THIS IS THE END OF THE SCRIPT" charset: @"ansi" caseSensitive: YES];
    
    //  Close the channel.
    //  It is important to close the channel only after receiving the desired output.
    success = [ssh ChannelSendClose: [NSNumber numberWithInt: channelNum]];
    
    //  Get any remaining output..
    success = [ssh ChannelReceiveToClose: [NSNumber numberWithInt: channelNum]];
    
    //  Get the complete output for all the commands in the session.
    NSLog(@"%@",@"--- output ----");
    NSLog(@"%@",[ssh GetReceivedText: [NSNumber numberWithInt: channelNum] charset: @"ansi"]);
    
//    //  Send some commands and get the output.
//    NSString *strOutput = [ssh QuickCommand: @"ls | grep src" charset: @"ansi"];
//    if (ssh.LastMethodSuccess != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//    if (![strOutput isEqualToString:@"src"]) {
//        [ssh QuickCommand: @"mkdir src" charset: @"ansi"];
//        if (ssh.LastMethodSuccess != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            return;
//        }
//    }
//    [ssh QuickCommand: @"cd src" charset: @"ansi"];
//    if (ssh.LastMethodSuccess != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//    strOutput = [ssh QuickCommand: @"ls | grep dash" charset: @"ansi"];
//    if (ssh.LastMethodSuccess != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//    BOOL justCloned = FALSE;
//        if (![strOutput isEqualToString:@"dash"]) {
//            justCloned = TRUE;
//            [ssh QuickCommand: @"git clone https://github.com/QuantumExplorer/dash.git" charset: @"ansi"];
//            if (ssh.LastMethodSuccess != YES) {
//                NSLog(@"%@",ssh.LastErrorText);
//                return;
//            }
//        }
//    [ssh QuickCommand: @"cd dash" charset: @"ansi"];
//    if (ssh.LastMethodSuccess != YES) {
//        NSLog(@"%@",ssh.LastErrorText);
//        return;
//    }
//    if (!justCloned) {
//        [ssh QuickCommand: @"git pull" charset: @"ansi"];
//        if (ssh.LastMethodSuccess != YES) {
//            NSLog(@"%@",ssh.LastErrorText);
//            return;
//        }
//    }
//    NSLog(@"%@",@"---- ls | grep src ----");
//    NSLog(@"%@",strOutput);
    
    [ssh Disconnect];
    
    return;
}

- (NSString *)runCommandString:(NSString *)commandToRun
{
    
    NSString *output = [[NSString alloc] initWithData:[self runCommand:commandToRun] encoding:NSUTF8StringEncoding];
    return output;
}

- (NSDictionary *)runCommandJSON:(NSString *)commandToRun
{
    NSData * data = [self runCommand:commandToRun];
    NSError * error = nil;
    NSDictionary *output = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error: &error];
    return output;
}

- (void)startInstances:(NSInteger)count {
    NSString *output = [self runCommandString:[NSString stringWithFormat:@"ec2 run-instances --image-id ami-a259d3c2 --count %ld --instance-type t2.micro --key-name SSH_KEY_DASH_PLAYGROUND --security-group-ids sg-8a11f5f1 --instance-initiated-shutdown-behavior terminate --subnet-id subnet-b764acd2",(long)count]];
    NSLog(@"%@",output);
}

- (void)stopInstance:(NSString*)instanceId {
    NSString *output = [self runCommandString:[NSString stringWithFormat:@"ec2 stop-instances --instance-ids %@",instanceId]];
    NSLog(@"%@",output);
}

-(NSUInteger)stateForStateName:(NSString*)string {
    
    InstanceState_Stopped = 0,
    InstanceState_Running = 1,
    InstanceState_Terminated = 2,
    InstanceState_Pending = 3,
    InstanceState_Stopping = 4,
    InstanceState_Rebooting = 5,
    InstanceState_Shutting_Down = 6,
    
    if ([string isEqualToString:@"running"]) {
        return 0;
    } else if ([string isEqualToString:@"pending"]) {
        
    }
}

-(void)getInstances {
    NSDictionary *output = [self runCommandJSON:@"ec2 describe-instances --filter Name=key-name,Values=SSH_KEY_DASH_PLAYGROUND"];
    NSArray * reservations = output[@"Reservations"];
    NSMutableArray * instances = [NSMutableArray array];
    if ([reservations count]) {
     NSLog(@"%@",reservations[0][@"Instances"]);
        for (NSDictionary * dictionary in reservations[0][@"Instances"]) {
            NSDictionary * rDict = [NSMutableDictionary dictionary];
            [rDict setValue:[dictionary valueForKey:@"InstanceId"] forKey:@"instanceId"];
            [rDict setValue:[dictionary valueForKey:@"PublicIpAddress"] forKey:@"publicIP"];
            [rDict setValue:([[dictionary valueForKeyPath:@"State.Name"]  isEqual:@"running"]?@(1):@(0)) forKey:@"instanceState"];
            [instances addObject:rDict];
        }
    }
    NSArray * array = [[[DPDataStore sharedInstance] allMasternodes] arrayReferencedByKeyPath:@"instanceId"];
    
    NSDictionary * referencedInstances = [instances dictionaryReferencedByKeyPath:@"instanceId"];
    BOOL needsSave = FALSE;
    for (NSString* reference in referencedInstances) {
        if ([array containsObject:reference]) continue;
        needsSave = TRUE;
        [[DPDataStore sharedInstance] addMasternode:referencedInstances[reference] saveContext:FALSE];
    }
    if (needsSave) {
        [[DPDataStore sharedInstance] saveContext];
    }
}

#pragma mark -
#pragma mark Instances



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
