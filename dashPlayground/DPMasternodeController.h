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
#import "ProjectTypeTransformer.h"

@class Masternode;

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
- (void)getInstancesClb:(dashMessageClb)clb;
- (void)createInstanceWithInitialAMI:(dashStateClb)clb serverType:(NSString*)serverType;
//- (void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb;
- (void)setUpMasternodeDashd:(Masternode*)masternode clb:(dashMessageClb)clb;
- (void)setUpMasternodeConfiguration:(Masternode*)masternode onChainName:(NSString*)chainName clb:(dashSuccessInfo)clb;
- (void)setUpMasternodeSentinel:(Masternode*)masternode clb:(dashMessageClb)clb;

- (void)startMasternodeOnRemote:(Masternode*)masternode localChain:(NSString*)localChain clb:(dashInfoClb)clb;

-(void)checkMasternode:(Masternode*)masternode;
-(void)checkMasternodeChainNetwork:(Masternode*)masternode clb:(dashMessageClb)clb;

//-(NSDictionary*)retrieveConfigurationInfoThroughSSH:(NSManagedObject*)masternode;

- (NSDictionary *)runAWSCommandJSON:(NSString *)commandToRun checkError:(BOOL)withError;
- (NSData *)runAWSCommand:(NSString *)commandToRun checkError:(BOOL)withError;
- (NSString *)runAWSCommandString:(NSString *)commandToRun checkError:(BOOL)withError;

-(void)setSshPath:(NSString*)sshPath;
-(NSString*)sshPath;
-(NSString*)getSshName;
-(void)setSshName:(NSString*)sshName;

-(void)createBackgroundSSHSessionOnMasternode:(Masternode*)masternode clb:(dashSSHClb)clb;

//- (NSDictionary *)dictionaryReferencedByKeyPath:(NSString*)key;

-(void)checkMasternodeIsInstalled:(Masternode*)masternode clb:(dashBoolClb)clb;
-(void)checkMasternodeIsProperlyInstalled:(Masternode*)masternode onSSH:(NMSSHSession*)ssh;
-(void)checkMasternodeSentinel:(Masternode*)masternode clb:(dashMessageClb)clb;
-(NMSSHSession*)connectInstance:(Masternode*)masternode;
-(NSString*)getResponseExecuteCommand:(NSString*)command onSSH:(NMSSHSession*)ssh error:(NSError*)error;
-(NSString*)createSentinelConfFileForMasternode:(Masternode*)masternode;
//-(void)checkMasternodeChainNetwork:(NSManagedObject*)masternode;
//-(void)updateMasternode:(NSManagedObject*)masternode;
-(void)updateMasternodeAttributes:(Masternode*)masternode clb:(dashMessageClb)clb;

-(void)startDashdOnRemote:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)stopDashdOnRemote:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;

-(void)addNodeToLocal:(Masternode*)masternode clb:(dashMessageClb)clb;
-(void)addNodeToRemote:(Masternode*)masternode toPublicIP:(NSString*)publicIP clb:(dashMessageClb)clb;
-(void)sendRPCCommandString:(NSString*)command toMasternode:(Masternode*)masternode clb:(dashMessageClb)clb;
-(void)getInfo:(Masternode*)masternode clb:(dashInfoClb)clb;

-(void)configureMasternodeSentinel:(NSArray*)AllMasternodes;
-(void)registerProtxForLocal:(NSString*)publicIP localChain:(NSString*)localChain onClb:(dashMessageClb)clb;
-(void)registerProtxForLocal:(NSArray*)AllMasternodes;

-(void)setUpDevnet:(NSArray*)allMasternodes;
-(void)setUpMainNode:(Masternode*)masternode clb:(dashActiveClb)clb;
-(void)checkDevnetNetwork:(NSString*)chainName AllMasternodes:(NSArray*)allMasternodes;

-(InstanceState)stateForStateName:(NSString*)string;

-(void)validateMasternodeBlock:(NSArray*)masternodeObjects blockHash:(NSString*)blockHash clb:(dashMessageClb)clb;
-(void)reconsiderMasternodeBlock:(NSArray*)masternodeObjects blockHash:(NSString*)blockHash clb:(dashMessageClb)clb;
-(void)getBlockchainInfoForNodes:(NSArray*)masternodeObjects clb:(dashMessageClb)clb;
-(void)clearBannedOnNodes:(NSArray*)masternodeObjects withCallback:(dashMessageClb)clb;
-(void)wipeDataOnRemote:(Masternode*)masternode onClb:(dashMessageClb)clb;

-(void)checkRequiredPackagesAreInstalledOnMasternode:(Masternode*)masternode withClb:(dashActionClb)clb;
-(void)checkPackages:(NSArray*)packages areInstalledOnMasternode:(Masternode*)masternode withClb:(dashActionClb)clb;
-(void)checkRequiredPackagesAreInstalledInSession:(NMSSHSession*)sshSession withClb:(dashActionClb)clb;
-(void)checkPackages:(NSArray*)packages areInstalledInSession:(NMSSHSession*)sshSession withClb:(dashActionClb)clb;

-(void)installDependenciesForMasternode:(Masternode*)masternode inSession:(NMSSHSession*)sshSession withClb:(dashActionClb)clb;
-(void)gitCloneProjectWithRepositoryPath:(NSString*)repositoryPath toDirectory:(NSString*)directory andSwitchToBranch:(NSString*)branchName inSSHSession:(NMSSHSession *)ssh dashClb:(dashMessageClb)clb;
-(void)updateGitInfoForMasternode:(Masternode*)masternode forProject:(DPRepositoryProject)project clb:(dashInfoClb)clb;

- (void)configureInsightOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb;
-(void)checkInsightIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
- (void)installInsightOnMasternode:(Masternode*)masternode clb:(dashMessageClb)clb;

-(void)configureDapiOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)checkDapiIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)checkDapiIsConfiguredOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb;
-(void)installDapiOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;

-(void)configureDriveOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)checkDriveIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)checkDriveIsConfiguredOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb;
-(void)installDriveOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;

-(void)installIpfsOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)checkIpfsIsRunningOnMasternode:(Masternode*)masternode completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;
-(void)configureIpfsOnMasternode:(Masternode*)masternode forceUpdate:(BOOL)forceUpdate completionClb:(dashActionClb)clb messageClb:(dashMessageClb)messageClb;

-(void)turnProject:(DPRepositoryProject)project onOrOff:(BOOL)onOff onMasternode:(Masternode*)masternode completionClb:(dashActionClb)completionClb messageClb:(dashMessageClb)messageClb;

@end
