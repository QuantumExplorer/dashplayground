//
//  DPLocalNodeController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/5/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DPLocalNodeController.h"

@implementation DPLocalNodeController

- (NSData *)runDashRPCCommand:(NSString *)commandToRun
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Users/samuelw/Documents/src/dash/src/dash-cli"];
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    [task launch];
    
    return [file readDataToEndOfFile];
}

-(NSString*)getInfo {
    NSString *output = [self runDashRPCCommandString:@"-testnet getinfo"];
    if ([output hasPrefix:@"error"] || [output isEqualToString:@""]) return nil;
    NSLog(@"o %@",output);
    return output;
}

-(NSDictionary*)getSyncStatus {
    NSData *output = [self runDashRPCCommand:@"-testnet mnsync status"];
    NSError * error = nil;
    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:output options:0 error:&error];
    if (error) return nil;
    return dictionary;
}

dispatch_queue_t dashCallbackBackgroundQueue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.quantumexplorer.dashplayground.backgroundQueue", 0);
    });
    return queue;
}

dispatch_queue_t dashCallbackBackgroundMNStatusQueue() {
    static dispatch_once_t queueCreationGuard;
    static dispatch_queue_t queue;
    dispatch_once(&queueCreationGuard, ^{
        queue = dispatch_queue_create("com.quantumexplorer.dashplayground.mnStatus", 0);
    });
    return queue;
}

- (void)checkDash:(dashActiveClb)clb {
    [self checkDashTries:1 clb:clb];
}

- (void)checkDashTries:(NSUInteger)timesToTry clb:(dashActiveClb)clb {
    dispatch_async(dashCallbackBackgroundQueue(), ^{
        int tries = 0;
        while (![self getInfo] && tries < timesToTry) {
            tries++;
            sleep(5);
        }
        if (tries == timesToTry) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(YES);
            });
        }
    });
}

- (void)checkDashStopped:(dashActiveClb)clb {
    dispatch_async(dashCallbackBackgroundQueue(), ^{
        int tries = 0;
        while ([self getInfo] && tries < 5) {
            tries++;
            sleep(5);
        }
        if (tries == 5) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(YES);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO);
            });
        }
    });
}

- (void)startDash:(dashClb)clb
{
    [self checkDash:^(BOOL active) {
        if (!active) {
            NSString * commandToRun = @"-testnet";
            
            NSTask *task = [[NSTask alloc] init];
            [task setLaunchPath:@"/Users/samuelw/Documents/src/dash/src/dashd"];
            
            NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
            NSLog(@"run command:%@", commandToRun);
            [task setArguments:arguments];
            
            NSPipe *pipe = [NSPipe pipe];
            [task setStandardOutput:pipe];
            
            [task launch];
            
            [self checkDashTries:5 clb:^(BOOL active) {
                if (active) {
                    clb(active,@"Dash server started");
                } else {
                    clb(active,@"Dash server didn't start up");
                }
                
            }];
        } else {
            clb(active,@"Dash server active");
        }
    }];
    
}

- (void)stopDash:(dashClb)clb
{
    
    NSString * commandToRun = @"-testnet stop";
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/Users/samuelw/Documents/src/dash/src/dash-cli"];
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    [task launch];
    
    [self checkDashStopped:^(BOOL active) {
        if (active) {
            clb(!active,@"Dash server didn't stop successfully");
        } else {
            clb(!active,@"Dash server stopped");
        }
    }];
}

-(void)checkSyncStatus:(dashSyncClb)clb {
    dispatch_async(dashCallbackBackgroundMNStatusQueue(), ^{
        int tries = 0;
        NSDictionary * dictionary = [self getSyncStatus];
        while (!dictionary[@"IsSynced"] && tries < 100) {
            sleep(5);
            tries++;
            dictionary = [self getSyncStatus];
        }
        if (tries == 100) {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(NO);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                clb(YES);
            });
        }
    });
}

- (NSString *)runDashRPCCommandString:(NSString *)commandToRun
{
    
    NSString *output = [[NSString alloc] initWithData:[self runDashRPCCommand:commandToRun] encoding:NSUTF8StringEncoding];
    return output;
}

-(NSArray*)outputs {
    NSCharacterSet * bracketCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"{} "] ;
    NSCharacterSet * quotesCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\n\r "] ;
    NSString * linesString = [[[self runDashRPCCommandString:@"-testnet masternode outputs"] stringByTrimmingCharactersInSet:bracketCharacterSet] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSArray * split = [linesString componentsSeparatedByString:@","];
    NSMutableArray * rArray = [NSMutableArray array];
    for (NSString * line in split) {
        NSArray * components = [line componentsSeparatedByString:@":"];
        [rArray addObject:@[[components[0] stringByTrimmingCharactersInSet:quotesCharacterSet],@([[components[1] stringByTrimmingCharactersInSet:quotesCharacterSet] integerValue])]];
    }
    return [rArray copy];
}

- (void)startRemote:(NSManagedObject*)masternode {
    NSString * string = [NSString stringWithFormat:@"-testnet masternode start-alias %@",[masternode valueForKey:@"instanceId"]];
    //return string;
}



#pragma mark - Singleton methods

+ (DPLocalNodeController *)sharedInstance
{
    static DPLocalNodeController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPLocalNodeController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}


@end
