//
//  VolumeViewController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 2/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#ifndef VolumeViewController_h
#define VolumeViewController_h


#endif /* VolumeViewController_h */
#import <Cocoa/Cocoa.h>
#import "DPTableView.h"

@interface VolumeViewController : NSWindowController <NSTableViewDataSource,NSApplicationDelegate> {}

-(void)showAMIWindow:(NSManagedObject*)object;
-(void)setAmiIdToRepositoryView:(NSString*)amiId repoPath:(NSString*)repoPath;

@end
