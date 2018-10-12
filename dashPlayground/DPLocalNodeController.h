//
//  DPLocalNodeController.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/5/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MasternodeSyncStatusTransformer.h"
#import "DashCallbacks.h"

#define DASHD_PATH @"DASHD_PATH"
#define DASHCLI_PATH @"DASHCLI_PATH"

@interface DPLocalNodeController : NSObject

@property (atomic,assign) MasternodeSync syncStatus;
@property (nonatomic,copy) NSString * dashCliPath;
@property (nonatomic,copy) NSString * dashDPath;

- (void)startDash:(dashMessageClb)clb forChain:(NSString*)chainNetwork;

- (void)stopDash:(dashMessageClb)clb forChain:(NSString*)chainNetwork;

- (void)checkDash:(dashActiveClb)clb forChain:(NSString*)chainNetwork;

- (void)checkDashStopped:(dashActiveClb)clb forChain:(NSString*)chainNetwork;

-(NSDictionary*)getSyncStatus:(NSString*)chainNetwork;

-(NSArray*)outputs:(NSString*)chainNetwork;

- (NSData *)runDashRPCCommand:(NSString *)commandToRun checkError:(BOOL)withError onClb:(dashDataClb)clb;

- (void)runDashRPCCommandString:(NSString *)commandToRun forChain:(NSString*)chainNetwork onClb:(dashMessageClb)clb;

- (NSString*)runDashRPCCommandString:(NSString *)commandToRun forChain:(NSString*)chainNetwork;

- (void)runDashRPCCommandArray:(NSString *)commandToRun checkError:(BOOL)withError onClb:(dashDictInfoClb)clb;

-(NSDictionary *)runDashRPCCommandArrayWithArray:(NSArray *)commandToRun;

- (NSString *)runDashRPCCommandStringWithArray:(NSArray *)commandToRun;

-(NSDictionary*)masternodeInfoInMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode;

-(void)updateMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode clb:(dashMessageClb)clb;

+(DPLocalNodeController*)sharedInstance;

-(NSString*)masterNodePath;

-(void)setMasterNodePath:(NSString*)masterNodePath;

- (NSMutableDictionary *)runCurlCommandJSON:(NSString *)commandToRun checkError:(BOOL)withError;

@end
