//
//  DPVersioningController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 30/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VersioningViewController.h"
#import "DashCallbacks.h"
#import "ProjectTypeTransformer.h"

@protocol DPVersionControllerDelegate

-(void)versionControllerRelayMessage:(NSString*)message;

@end

@class Masternode;

@interface DPVersioningController : NSObject

@property (nonatomic,weak) id<DPVersionControllerDelegate> delegate;

+ (DPVersioningController*)sharedInstance;

- (void)fetchGitCommitInfoOnMasternode:(Masternode*)masternode forProject:(DPRepositoryProject)project clb:(dashArrayClb)clb;

- (NSMutableArray*)splitGitCommitArrayData:(NSDictionary*)dict;

- (void)updateCore:(NSString*)publicIP repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch commitHead:(NSString*)commitHead;

- (void)updateDapi:(NSString*)publicIP repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch commitHead:(NSString*)commitHead;

@end
