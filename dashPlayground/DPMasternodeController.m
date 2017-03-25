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

@interface DPMasternodeController ()

@property (strong, nonatomic) NSManagedObjectContext *mainObjectContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

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

- (NSString *)sshIn:(NSString*)ip
{
    NSString * commandToRun = [NSString stringWithFormat:@"-i ~/Documents/SSH_KEY_DASH_PLAYGROUND.pem ubuntu@%@",ip];
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/ssh"];
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData * data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",output);
    return output;
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
            [rDict setValue:[dictionary valueForKeyPath:@"State.Name"] forKey:@"state"];
            [instances addObject:rDict];
        }
    }
    AppDelegate * delegate = [[NSApplication sharedApplication] delegate];
    NSArray * array = [self allInstancesInContext:delegate.managedObjectContext];
    
    NSLog(@"%@",[instances arrayReferencedByKeyPath:@"instanceId"]);
}

#pragma mark -
#pragma mark Instances

-(NSArray*)allInstancesInContext:(NSManagedObjectContext*)context {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Masternode"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    
    NSArray *syncableItems = [(AppDelegate*)[NSApplication sharedApplication].delegate executeFetchRequest:fetchRequest inContext:context error:&error];
    if (!syncableItems) {
        return @[];
    } else  {
        return syncableItems;
    }
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
