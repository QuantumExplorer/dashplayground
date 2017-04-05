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

@interface DPMasternodeController : NSObject

+(DPMasternodeController*)sharedInstance;

- (void)runInstances:(NSInteger)count;
- (void)startInstance:(NSString*)instanceId;
- (void)stopInstance:(NSString*)instanceId;
- (void)terminateInstance:(NSString*)instanceId;
- (void)getInstances;

- (void)setUp:(NSManagedObject*)masternode;
- (void)configureMasternode:(NSManagedObject*)masternode;
- (void)startRemote:(NSManagedObject*)masternode;

- (NSString *)runDashRPCCommandString:(NSString *)commandToRun;

@end
