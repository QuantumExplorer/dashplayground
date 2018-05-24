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
#import <NMSSH/NMSSH.h>
#import "MasternodesViewController.h"

typedef void (^dashPercentageClb)(NSString * message,float percentage);

@interface DPMasternodeController : NSObject

+(DPMasternodeController*)sharedInstance;

-(void)setViewController:(MasternodesViewController*)controller;

-(void)setUpInstances:(NSInteger)count onBranch:(NSManagedObject*)branch clb:(dashInfoClb)clb onRegion:(NSMutableArray*)regionArray;
- (void)runInstances:(NSInteger)count clb:(dashStateClb)clb;
- (void)startInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)stopInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)terminateInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)getInstancesClb:(dashClb)clb;
- (void)createInstanceWithInitialAMI:(dashStateClb)clb;
- (void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb;
- (void)setUpMasternodeDashd:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)setUpMasternodeConfiguration:(NSManagedObject*)masternode onViewCon:(MasternodesViewController*)viewCon clb:(dashClb)clb;
- (void)setUpMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)configureRemoteMasternode:(NSManagedObject*)masternode;

- (void)startDashd:(NSManagedObject*)masternode onViewCon:(MasternodesViewController*)viewCon clb:(dashInfoClb)clb;

-(void)checkMasternode:(NSManagedObject*)masternode;

//-(NSDictionary*)retrieveConfigurationInfoThroughSSH:(NSManagedObject*)masternode;

- (NSDictionary *)runAWSCommandJSON:(NSString *)commandToRun;
- (NSData *)runAWSCommand:(NSString *)commandToRun;
- (NSString *)runAWSCommandString:(NSString *)commandToRun;

-(void)setSshPath:(NSString*)sshPath;
-(NSString*)sshPath;

//- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key;

- (void)checkMasternodeIsInstalled:(NSManagedObject*)masternode clb:(dashBoolClb)clb;
-(void)updateGitInfoForMasternode:(NSManagedObject*)masternode clb:(dashInfoClb)clb;

-(NMSSHSession*)connectInstance:(NSManagedObject*)masternode;
-(NSString*)getResponseExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error;

@end
