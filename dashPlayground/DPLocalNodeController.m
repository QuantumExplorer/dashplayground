//
//  DPLocalNodeController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/5/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DPLocalNodeController.h"
#import "DPMasternodeController.h"
#import "Notification.h"
#import "DialogAlert.h"
#import "DPDataStore.h"
#import "NSArray+SWAdditions.h"

#define DASHCLIPATH @"dashCliPath"
#define DASHDPATH @"dashDPath"
#define MASTERNODEPATH @"masterNodePath"

@implementation DPLocalNodeController

-(NSString*)dashCliPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:DASHCLIPATH];
}

-(void)setDashCliPath:(NSString*)dashCliPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:dashCliPath forKey:DASHCLIPATH];
}

-(NSString*)dashDPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:DASHDPATH];
}

-(void)setDashDPath:(NSString*)dashDPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:dashDPath forKey:DASHDPATH];
}

-(NSString*)masterNodePath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:MASTERNODEPATH];
}

-(void)setMasterNodePath:(NSString*)masterNodePath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:masterNodePath forKey:MASTERNODEPATH];
}

- (NSData *)runDashRPCCommand:(NSString *)commandToRun
{
    if (![self dashCliPath]) return nil;
    NSTask *task = [[NSTask alloc] init];
    NSLog(@"%@",[self dashCliPath]);
    [task setLaunchPath:[self dashCliPath]];
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];

    NSFileHandle *file = [pipe fileHandleForReading];
    
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    
    NSFileHandle *error = [errorPipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit]; //Toey, wait until finish launching task to show error.
    
    //Toey, add this stuff to show error alert.
    NSData * dataError = [error readDataToEndOfFile];
    NSString * strError = [[NSString alloc] initWithData:dataError encoding:NSUTF8StringEncoding];
    if([strError length] != 0) {
        return dataError;
    }
    
    return [file readDataToEndOfFile];
}

- (NSDictionary *)runDashRPCCommandArrayWithArray:(NSArray *)commandToRun
{
    NSData *output = [self runDashRPCCommandFromArray:commandToRun];
    if(output == nil) return nil;
    NSError * error = nil;
    NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:output options:0 error:&error];
    if (error) return nil;
    return dictionary;
}

- (NSString *)runDashRPCCommandStringWithArray:(NSArray *)commandToRun
{
    NSData *data = [self runDashRPCCommandFromArray:commandToRun];
    if(data == nil) return nil;
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

- (NSData *)runDashRPCCommandFromArray:(NSArray *)commandToRun
{
    if (![[DPLocalNodeController sharedInstance] dashCliPath]) return nil;
    NSTask *task = [[NSTask alloc] init];
    NSLog(@"%@",[[DPLocalNodeController sharedInstance] dashCliPath]);
    [task setLaunchPath:[[DPLocalNodeController sharedInstance] dashCliPath]];
    
    //    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:commandToRun];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file = [pipe fileHandleForReading];
    
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    
    NSFileHandle *error = [errorPipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit]; //Toey, wait until finish launching task to show error.
    
    //Toey, add this stuff to show error alert.
    NSData * dataError = [error readDataToEndOfFile];
    NSString * strError = [[NSString alloc] initWithData:dataError encoding:NSUTF8StringEncoding];
    dispatch_async(dispatch_get_main_queue(), ^{
        if([strError length] != 0){
            [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:[NSString stringWithFormat:@"%@", strError]];
            NSLog(@"%@", strError);
        }
    });
    
    if([strError length] != 0){
        return nil;
    }
    
    return [file readDataToEndOfFile];
}

-(NSString*)getInfo:(NSString*)chainNetwork {
    NSString *output = [self runDashRPCCommandString:@"getinfo" forChain:chainNetwork];
    if ([output hasPrefix:@"error"] || [output isEqualToString:@""]) return nil;
    NSLog(@"o %@",output);
    return output;
}

-(NSDictionary*)getSyncStatus:(NSString*)chainNetwork {
    NSData *output = [self runDashRPCCommand:[NSString stringWithFormat:@"-%@ mnsync status", chainNetwork]];
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

- (void)checkDash:(dashActiveClb)clb forChain:(NSString*)chainNetwork {
    [self checkDashTries:3 clb:clb forChain:chainNetwork];
}

- (void)checkDashTries:(NSUInteger)timesToTry clb:(dashActiveClb)clb forChain:(NSString*)chainNetwork {
    dispatch_async(dashCallbackBackgroundQueue(), ^{
        int tries = 0;
        while (![self getInfo:chainNetwork] && tries < timesToTry) {
            tries++;
            sleep(5);
        }
        if (tries == timesToTry) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STOPPED object:nil];
                clb(NO);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STARTED object:nil];
                clb(YES);
            });
        }
    });
}

- (void)checkDashStopped:(dashActiveClb)clb forChain:(NSString*)chainNetwork {
    dispatch_async(dashCallbackBackgroundQueue(), ^{
        int tries = 0;
        while ([self getInfo:chainNetwork] && tries < 5) {
            tries++;
            sleep(5);
        }
        if (tries == 5) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STARTED object:nil];
                clb(YES);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STOPPED object:nil];
                clb(NO);
            });
        }
    });
}

- (void)startDash:(dashClb)clb forChain:(NSString*)chainNetwork
{
    if (![self dashDPath]) return;
    [self checkDash:^(BOOL active) {
        if (!active) {
            [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STARTING object:nil];
            
            NSString * commandToRun = @"";
            if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
                commandToRun = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999", chainNetwork];
            }
            else {
                commandToRun = [NSString stringWithFormat:@"-%@", chainNetwork];
            }
            
            NSTask *task = [[NSTask alloc] init];
            NSLog(@"%@",[self dashDPath]);
            [task setLaunchPath:[self dashDPath]];
            
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
                
            } forChain:chainNetwork];
        } else {
            clb(active,@"Dash server active");
        }
    } forChain:chainNetwork];
    
}

- (void)stopDash:(dashClb)clb forChain:(NSString*)chainNetwork
{
    if (![self dashCliPath]) return;
    
    NSString * commandToRun = [NSString stringWithFormat:@"-%@ stop", chainNetwork];
    if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        commandToRun = [NSString stringWithFormat:@"-%@ -rpcport=12998 -port=12999 stop", chainNetwork];
    }
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:[self dashCliPath]];
    
    NSArray *arguments = [commandToRun componentsSeparatedByString:@" "];
    NSLog(@"run command:%@", commandToRun);
    [task setArguments:arguments];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    [task launch];
    
    [self checkDashStopped:^(BOOL active) {
        if (active) {
            [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STARTED object:nil];
            clb(!active,@"Dash server didn't stop successfully");
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:nDASHD_STOPPED object:nil];
            clb(!active,@"Dash server stopped");
        }
    } forChain:chainNetwork];
}

-(void)checkSyncStatus:(dashSyncClb)clb forChain:(NSString*)chainNetwork {
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

- (NSString *)runDashRPCCommandString:(NSString *)commandToRun forChain:(NSString*)chainNetwork
{
    NSString * prefixCommand;
    NSString *output;
//    if ([chainNetwork isEqualToString:@"mainnet"] || [chainNetwork isEqualToString:@"testnet"]) prefixCommand = [NSString stringWithFormat:@"-%@",chainNetwork];
//    else prefixCommand = [NSString stringWithFormat:@"-devnet='%@'",chainNetwork];
    if(chainNetwork == nil) {
        output = [[NSString alloc] initWithData:[self runDashRPCCommand:[NSString stringWithFormat:@"%@",commandToRun]] encoding:NSUTF8StringEncoding];
    }
    else {
        if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
            chainNetwork = [NSString stringWithFormat:@"%@ -rpcport=12998 -port=12999", chainNetwork];
        }
        prefixCommand = [NSString stringWithFormat:@"-%@",chainNetwork];
        NSString * fullCommand = [NSString stringWithFormat:@"%@ %@",prefixCommand,commandToRun];
        output = [[NSString alloc] initWithData:[self runDashRPCCommand:fullCommand] encoding:NSUTF8StringEncoding];
    }
    
    return output;
}

- (NSDictionary *)runDashRPCCommandArray:(NSString *)commandToRun
{
    NSError* error;
    NSDictionary* outputs = [NSJSONSerialization JSONObjectWithData:[self runDashRPCCommand:commandToRun]
                                                         options:kNilOptions
                                                           error:&error];
    return outputs;
}

-(NSArray*)outputs:(NSString*)chainNetwork {
    NSCharacterSet * bracketCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"{} "] ;
    NSCharacterSet * quotesCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\n\r "] ;
    NSString * linesString = [[[self runDashRPCCommandString:@"masternode outputs" forChain:chainNetwork] stringByTrimmingCharactersInSet:bracketCharacterSet] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    if([linesString isEqualToString:@"}"]) {
        return nil;
    }
    
    NSArray * split = [linesString componentsSeparatedByString:@","];
    NSMutableArray * rArray = [NSMutableArray array];
    for (NSString * line in split) {
        NSArray * components = [line componentsSeparatedByString:@":"];
        [rArray addObject:@[[components[0] stringByTrimmingCharactersInSet:quotesCharacterSet],@([[components[1] stringByTrimmingCharactersInSet:quotesCharacterSet] integerValue])]];
    }
    return [rArray copy];
}

-(NSDictionary*)masternodeInfoInMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode {
    if (![self masterNodePath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"masternode.conf" exPath:@"~Library/Application Support/Dashcore/testnet3"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [self setMasterNodePath:pathString];
        }
    }
    
    NSMutableString *fullpath = [self getMastetnodeFullPath];

    NSError * error = nil;
    NSString *contents = [NSString stringWithContentsOfFile:fullpath encoding:NSUTF8StringEncoding error:&error];
    NSArray * lines = [contents componentsSeparatedByString:@"\n"];
    NSString * importantLine = nil;
    for (int i = ((int)[lines count]) - 1;i> -1;i--) {

                if ([lines[i] hasPrefix:[masternode valueForKey:@"instanceId"]]) {
                    importantLine = lines[i];
                }
    }
    if (importantLine) {
        NSArray * info = [importantLine componentsSeparatedByString:@" "];
        if ([info count] == 5) {
            NSString * publicIP = [info[1] componentsSeparatedByString:@":"][0];
            return @{@"instanceId":info[0],@"publicIP":publicIP,@"key":info[2],@"transactionId":info[3],@"transactionOutputIndex":@([info[4] intValue])};
        }
    }
    return @{};
}

-(void)updateMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode clb:(dashClb)clb {
    if (![self masterNodePath]) {
        DialogAlert *dialog=[[DialogAlert alloc]init];
        NSAlert *findPathAlert = [dialog getFindPathAlert:@"masternode.conf" exPath:@"~Library/Application Support/Dashcore/testnet3"];
        
        if ([findPathAlert runModal] == NSAlertFirstButtonReturn) {
            //Find clicked
            NSString *pathString = [dialog getLaunchPath];
            [self setMasterNodePath:pathString];
        }
    }
    __block NSManagedObject * object = masternode;
    [self checkDash:^(BOOL active) {
        int connectCount = 0;
        if(active != YES) {
            clb(NO, @"cannot connect to dash server. Please start it first.");
            connectCount = connectCount+1;
            if(connectCount == 3) return;
        }
        else {
            [self stopDash:^(BOOL success, NSString *message) {
                if (success) {
                    NSString *fullpath = [self getMastetnodeFullPath];
                    NSError * error = nil;
                    NSString *contents = [NSString stringWithContentsOfFile:fullpath encoding:NSUTF8StringEncoding error:&error];
                    NSMutableArray * lines = [[contents componentsSeparatedByString:@"\n"] mutableCopy];
                    NSMutableArray * specialLines = [NSMutableArray array];
                    for (int i = ((int)[lines count]) - 1;i> -1;i--) {
                        if ([lines[i] hasPrefix:@"#"]) {
                            [specialLines addObject:[lines objectAtIndex:i]];
                            [lines removeObjectAtIndex:i];
                        } else
                            if ([lines[i] isEqualToString:@""]) {
                                [lines removeObjectAtIndex:i];
                            } else
                                if ([lines[i] hasPrefix:[object valueForKey:@"instanceId"]]) {
                                    [lines removeObjectAtIndex:i];
                                }
                    }
                    [lines addObject:[NSString stringWithFormat:@"%@ %@:19999 %@ %@ %@",[object valueForKey:@"instanceId"],[object valueForKey:@"publicIP"],[object valueForKey:@"key"],[object valueForKey:@"transactionId"],[object valueForKey:@"transactionOutputIndex"]]];
                    NSString * content = [[[specialLines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"] stringByAppendingString:[lines componentsJoinedByString:@"\n"]];
                    [content writeToFile:fullpath
                              atomically:NO
                                encoding:NSStringEncodingConversionAllowLossy
                                   error:nil];
                    if (error) {
                        if (active) {
                            [self startDash:^(BOOL success, NSString *message) {
                                return clb(FALSE,@"Error writing to file");
                            } forChain:[masternode valueForKey:@"chainNetwork"]];
                        } else {
                            return clb(FALSE,@"Error writing to file");
                        }
                    } else {
                        if (active) {
                            [self startDash:^(BOOL success, NSString *message) {
                                return clb(success,message);
                            } forChain:[masternode valueForKey:@"chainNetwork"]];
                        } else {
                            return clb(TRUE,nil);
                        }
                    }
                } else {
                    clb(FALSE,@"Error stopping dash server to place configuration file.");
                }
            } forChain:[masternode valueForKey:@"chainNetwork"]];
        }
    } forChain:[masternode valueForKey:@"chainNetwork"]];
}

- (NSMutableString*)getMastetnodeFullPath {
    
    NSMutableString *fullpath = [NSMutableString string];
    NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
    
    NSArray * paths = [[[DPLocalNodeController sharedInstance] masterNodePath] componentsSeparatedByString:@"/"];
    NSMutableArray *pathClone = [NSMutableArray arrayWithArray:paths];
    
    if ([chainNetwork rangeOfString:@"testnet"].location != NSNotFound) {
        chainNetwork = @"testnet3";
        
    }
    else if ([chainNetwork rangeOfString:@"devnet"].location != NSNotFound) {
        chainNetwork = @"devnet-DRA";
    }
    
    if ([chainNetwork rangeOfString:@"mainnet"].location != NSNotFound) {
        [fullpath setString:[[DPLocalNodeController sharedInstance] masterNodePath]];
    }
    else {
        [pathClone replaceObjectAtIndex:[pathClone count]-2 withObject:chainNetwork];
        
        for(NSString *eachPath in pathClone) {
            [fullpath appendString:[NSString stringWithFormat:@"/%@", eachPath]];
        }
    }
    
    return fullpath;
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
