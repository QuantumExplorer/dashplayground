//
//  DPUnspentController.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 18/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "InstanceStateTransformer.h"
#import "DPLocalNodeController.h"
#import <NMSSH/NMSSH.h>

typedef void (^dashPercentageClb)(NSString * call,float percentage);

@interface DPUnspentController : NSObject

+(DPUnspentController*)sharedInstance;

-(void)retreiveUnspentOutput:(dashInfoClb)clb;
-(NSDictionary*)getUnspentList;
-(NSMutableArray*)processOutput:(NSDictionary*)unspentOutputs;
-(void)createTransaction:(NSUInteger)count label:(NSString*)label amount:(NSUInteger)amount allObjects:(NSArray*)allObjects;

@end
