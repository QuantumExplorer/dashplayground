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
#import "Repository+CoreDataClass.h"

@class Branch, Repository;

@interface DPRepositoryController : NSObject

-(void)addRepository:(NSString*)repositoryLocation forProject:(DPRepositoryProject)project forUser:(NSString*)user branchName:(NSString*)branchName isPrivate:(BOOL)isPrivate clb:(dashClb)clb;

-(void)updateBranchInfo:(Branch*)branch clb:(dashClb)clb;

- (void)setAMIForRepository:(Repository*)repository clb:(dashClb)clb;

+(DPRepositoryController*)sharedInstance;

@end
