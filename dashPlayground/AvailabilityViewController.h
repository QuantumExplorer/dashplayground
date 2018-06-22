//
//  AvailabilityViewController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 15/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>
#import "InstanceStateTransformer.h"
#import "DPLocalNodeController.h"

typedef void (^dashPercentageClb)(NSString * call,float percentage);

@interface AvailabilityViewController : NSWindowController

-(void)showAvailWindow:(NSInteger)count onBranch:(NSManagedObject*)branch clb:(dashInfoClb)clb;

@end
