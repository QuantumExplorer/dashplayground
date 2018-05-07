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

- (void)startDash:(dashClb)clb;

- (void)stopDash:(dashClb)clb;

- (void)checkDash:(dashActiveClb)clb;

- (void)checkDashStopped:(dashActiveClb)clb;

-(void)checkSyncStatus:(dashSyncClb)clb;

-(NSDictionary*)getSyncStatus;

-(NSArray*)outputs;

- (NSData *)runDashRPCCommand:(NSString *)commandToRun;

-(NSString *)runDashRPCCommandString:(NSString *)commandToRun;

-(NSDictionary*)masternodeInfoInMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode;

-(void)updateMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode clb:(dashClb)clb;

+(DPLocalNodeController*)sharedInstance;

@end
