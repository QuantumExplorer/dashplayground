//
//  DPMasternodeController.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "InstanceStateTransformer.h"
#import "DPLocalNodeController.h"

typedef void (^dashPercentageClb)(NSString * call,float percentage);

@interface DPMasternodeController : NSObject

+(DPMasternodeController*)sharedInstance;

-(void)setUpInstances:(NSInteger)count onBranch:(NSManagedObject*)branch clb:(dashInfoClb)clb;
- (void)runInstances:(NSInteger)count clb:(dashStateClb)clb;
- (void)startInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)stopInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)terminateInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)getInstancesClb:(dashClb)clb;
- (void)createInstanceWithInitialAMI:(dashStateClb)clb;

- (void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb;
- (void)setUpMasternodeDashd:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)setUpMasternodeConfiguration:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)setUpMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)configureRemoteMasternode:(NSManagedObject*)masternode;

- (void)startDashd:(NSManagedObject*)masternode clb:(dashInfoClb)clb;

-(void)checkMasternode:(NSManagedObject*)masternode;

-(NSDictionary*)retrieveConfigurationInfoThroughSSH:(NSManagedObject*)masternode;

- (NSDictionary *)runAWSCommandJSON:(NSString *)commandToRun;
- (NSData *)runAWSCommand:(NSString *)commandToRun;
- (NSString *)runAWSCommandString:(NSString *)commandToRun;

-(void)setSshPath:(NSString*)sshPath;
-(NSString*)sshPath;

- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key;

- (NSDictionary *)runTerminalCommandJSON:(NSString *)commandToRun;

@end
