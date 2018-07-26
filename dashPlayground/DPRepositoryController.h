//
//  DPRepositoryController.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/12/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "DashCallbacks.h"

@interface DPRepositoryController : NSObject

-(void)addRepositoryForUser:(NSString*)user repoName:(NSString*)repoName branch:(NSString*)branch clb:(dashClb)clb;

-(void)addPrivateRepositoryForUser:(NSString*)user repoName:(NSString*)repoName branch:(NSString*)branch clb:(dashClb)clb;

-(void)updateBranchInfo:(NSManagedObject*)branch clb:(dashClb)clb;

- (void)setAMIForRepository:(NSManagedObject*)repository clb:(dashClb)clb;

+(DPRepositoryController*)sharedInstance;

@end
