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

#define DASHD_PATH @"DASHD_PATH"
#define DASHCLI_PATH @"DASHCLI_PATH"

typedef void (^dashClb)(BOOL success,NSString * message);
typedef void (^dashActiveClb)(BOOL active);
typedef void (^dashSyncClb)(BOOL active);

@interface DPLocalNodeController : NSObject

@property (atomic,assign) MasternodeSync syncStatus;

- (void)startDash:(dashClb)clb;

- (void)stopDash:(dashClb)clb;

- (void)checkDash:(dashActiveClb)clb;

- (void)checkDashStopped:(dashActiveClb)clb;

-(void)checkSyncStatus:(dashSyncClb)clb;

-(NSDictionary*)getSyncStatus;

-(NSArray*)outputs;

- (NSData *)runDashRPCCommand:(NSString *)commandToRun;

-(NSString *)runDashRPCCommandString:(NSString *)commandToRun;

- (void)startRemote:(NSManagedObject*)masternode;

-(NSDictionary*)masternodeInfoInMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode;

-(void)updateMasternodeConfigurationFileForMasternode:(NSManagedObject*)masternode clb:(dashClb)clb;

+(DPLocalNodeController*)sharedInstance;

@end
