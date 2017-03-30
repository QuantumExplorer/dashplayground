//
//  DPMasternodeController.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum InstanceState {
    InstanceState_Stopped = 0,
    InstanceState_Running = 1,
    InstanceState_Terminated = 2,
    InstanceState_Pending = 3,
    InstanceState_Stopping = 4,
    InstanceState_Rebooting = 5,
    InstanceState_Shutting_Down = 6,
} InstanceState;

@interface DPMasternodeController : NSObject

+(DPMasternodeController*)sharedInstance;

-(void)startInstances:(NSInteger)count;
- (void)stopInstance:(NSString*)instanceId;
-(void)getInstances;

- (void)sshIn:(NSString*)ip;

@end
