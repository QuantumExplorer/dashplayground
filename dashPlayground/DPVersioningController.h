//
//  DPVersioningController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 30/7/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DPVersioningController : NSObject

+(DPVersioningController*)sharedInstance;

- (NSMutableArray*)getGitCommitInfo:(NSManagedObject*)masternode repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch;

- (NSMutableArray*)getGitCommitArrayData:(NSDictionary*)dict;

@end
