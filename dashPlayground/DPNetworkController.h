//
//  DPNetworkController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 25/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "InstanceStateTransformer.h"
#import <NMSSH/NMSSH.h>
#import "DPLocalNodeController.h"

@interface DPNetworkController : NSObject

+(DPNetworkController*)sharedInstance;

- (void)getDebugLogFileFromMasternode:(NSManagedObject*)masternode clb:(dashClb)clb;
- (void)findSpecificDataType:(NSString*)log datatype:(NSString*)type onClb:(dashClb)clb;

@end
