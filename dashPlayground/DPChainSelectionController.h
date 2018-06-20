//
//  DPChainSelectionController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 8/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "DPLocalNodeController.h"

@interface DPChainSelectionController : NSObject

+(DPChainSelectionController*)sharedInstance;

-(void)configureConfigDashFileForMasternode:(NSManagedObject*)masternode onChain:(NSString*)chain onName:(NSString*)devName onSporkAddr:(NSString*)sporkAddr onSporkKey:(NSString*)sporkKey onClb:(dashClb)clb;
-(void)executeConfigurationMethod:(NSString*)chainNetwork onName:(NSString*)chainNetworkName onMasternode:(NSManagedObject*)masternode onSporkAddr:(NSString*)sporkAddr onSporkKey:(NSString*)sporkKey;

@end
