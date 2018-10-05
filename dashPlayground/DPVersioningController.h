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

@interface DPVersioningController : NSObject {
    VersioningViewController *_versioningViewController;
}
@property(strong, nonatomic, readwrite) VersioningViewController *versioningViewController;

+ (DPVersioningController*)sharedInstance;

- (NSMutableArray*)getGitCommitInfo:(NSManagedObject*)masternode repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch;

- (NSMutableArray*)getGitCommitArrayData:(NSDictionary*)dict;

- (void)updateCore:(NSString*)publicIP repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch commitHead:(NSString*)commitHead;

- (void)updateDapi:(NSString*)publicIP repositoryUrl:(NSString*)repositoryUrl onBranch:(NSString*)gitBranch commitHead:(NSString*)commitHead;

@end
