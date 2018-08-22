//
//  DPBuildServerController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 3/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BuildServerViewController.h"
#import <NMSSH/NMSSH.h>
#import "DashCallbacks.h"

@interface DPBuildServerController : NSObject {
    BuildServerViewController *_buildServerViewController;
}

@property(strong, nonatomic, readwrite) BuildServerViewController *buildServerViewController;

+(DPBuildServerController*)sharedInstance;

-(NSString*)getBuildServerIP;
-(void)setBuildServerIP:(NSString*)ipAddress;

- (void)getAllRepository:(NMSSHSession*)buildServerSession dashClb:(dashMutaArrayInfoClb)clb;

- (void)getCompileData:(NMSSHSession*)buildServerSession dashClb:(dashMutaArrayInfoClb)clb;

- (void)cloneRepository:(NMSSHSession*)buildServerSession withGitLink:(NSString*)gitlink withBranch:(NSString*)branch type:(NSString*)type;

- (void)updateRepository:(NSManagedObject*)repoObject buildServerSession:(NMSSHSession*)buildServerSession;

- (void)copyDashAppToApache:(NSManagedObject*)repoObject buildServerSession:(NMSSHSession*)buildServerSession;

@end
