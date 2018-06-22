//
//  DPRepoModalController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 9/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MasternodesViewController.h"
#import "DPLocalNodeController.h"

@interface DPRepoModalController : NSObject

+(DPRepoModalController*)sharedInstance;

-(void)setViewController:(MasternodesViewController*)controller;
-(void)setUpMasternodeDashdWithSelectedRepo:(NSManagedObject*)masternode repository:(NSManagedObject*)repository clb:(dashClb)clb;
-(NSMutableArray*)getRepositoriesData;

@end
