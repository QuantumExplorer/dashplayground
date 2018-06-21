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

@interface DPMasternodeController : NSObject {
    MasternodesViewController *_masternodeViewController;
}
@property(strong, nonatomic, readwrite) MasternodesViewController *masternodeViewController;

+(DPMasternodeController*)sharedInstance;

- (void)setUpInstances:(NSInteger)count onBranch:(NSManagedObject*)branch clb:(dashInfoClb)clb onRegion:(NSMutableArray*)regionArray serverType:(NSString*)serverType;
- (void)runInstances:(NSInteger)count clb:(dashStateClb)clb serverType:(NSString*)serverType;
- (void)startInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)stopInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)terminateInstance:(NSString*)instanceId clb:(dashStateClb)clb;
- (void)getInstancesClb:(dashClb)clb;
- (void)createInstanceWithInitialAMI:(dashStateClb)clb serverType:(NSString*)serverType;
- (void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb;
- (void)setUpMasternodeDashd:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)setUpMasternodeConfiguration:(NSManagedObject*)masternode onChainName:(NSString*)chainName onSporkAddr:(NSString*)sporkAddr onSporkKey:(NSString*)sporkKey clb:(dashSuccessInfo)clb;
- (void)setUpMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb;

- (void)startMasternodeOnRemote:(NSManagedObject*)masternode localChain:(NSString*)localChain clb:(dashInfoClb)clb;
-(void)startDashdOnRemote:(NSManagedObject*)masternode onClb:(dashClb)clb;

-(void)checkMasternode:(NSManagedObject*)masternode;

//-(NSDictionary*)retrieveConfigurationInfoThroughSSH:(NSManagedObject*)masternode;

- (NSDictionary *)runAWSCommandJSON:(NSString *)commandToRun checkError:(BOOL)withError;
- (NSData *)runAWSCommand:(NSString *)commandToRun checkError:(BOOL)withError;
- (NSString *)runAWSCommandString:(NSString *)commandToRun checkError:(BOOL)withError;

-(void)setSshPath:(NSString*)sshPath;
-(NSString*)sshPath;

//- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key;

-(void)checkMasternodeIsInstalled:(NSManagedObject*)masternode clb:(dashBoolClb)clb;
-(void)updateGitInfoForMasternode:(NSManagedObject*)masternode clb:(dashInfoClb)clb;
-(void)checkMasternodeIsProperlyInstalled:(NSManagedObject*)masternode onSSH:(NMSSHSession*)ssh;
- (void)checkMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb;
-(NMSSHSession*)connectInstance:(NSManagedObject*)masternode;
-(NSString*)getResponseExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error;
-(NSString*)createSentinelConfFileForMasternode:(NSManagedObject*)masternode;
-(void)checkMasternodeChainNetwork:(NSManagedObject*)masternode;
-(void)updateMasternode:(NSManagedObject*)masternode;

-(void)stopDashdOnRemote:(NSManagedObject*)masternode onClb:(dashClb)clb;
- (void)addNodeToLocal:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)addNodeToRemote:(NSManagedObject*)masternode toPublicIP:(NSString*)publicIP clb:(dashClb)clb;
-(NSString *)sendRPCCommandString:(NSString*)command toMasternode:(NSManagedObject*)masternode;

-(void)configureMasternodeSentinel:(NSArray*)AllMasternodes;
- (void)registerProtxForLocal:(NSString*)publicIP onClb:(dashClb)clb;
- (void)registerProtxForLocal:(NSArray*)AllMasternodes;
- (NSData *)runAWSCommand:(NSString *)commandToRun checkError:(BOOL)withError onClb:(dashDataClb)clb;

- (void)setUpDevnet:(NSArray*)allMasternodes;
- (BOOL)setUpMainNode:(NSManagedObject*)masternode;
- (void)checkDevnetNetwork:(NSString*)chainName AllMasternodes:(NSArray*)allMasternodes;

@end
