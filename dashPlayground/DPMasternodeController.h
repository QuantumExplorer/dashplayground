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

- (void)runInstances:(NSInteger)count;
- (void)startInstance:(NSString*)instanceId;
- (void)stopInstance:(NSString*)instanceId;
- (void)terminateInstance:(NSString*)instanceId;
- (void)getInstances;

- (void)setUpMasternodeDashd:(NSManagedObject*)masternode;
- (void)setUpMasternodeConfiguration:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)setUpMasternodeSentinel:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)configureRemoteMasternode:(NSManagedObject*)masternode;

-(void)checkMasternode:(NSManagedObject*)masternode;

-(NSDictionary*)retrieveConfigurationInfoThroughSSH:(NSManagedObject*)masternode;

@end
