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

-(void)retreiveUnspentOutput:(dashInfoClb)clb forChain:(NSString*)chainNetwork;
-(NSDictionary*)getUnspentList:(NSString*)chainNetwork;
-(NSMutableArray*)processOutput:(NSDictionary*)unspentOutputs forChain:(NSString*)chainNetwork;
-(void)createTransaction:(NSInteger)count label:(NSString*)label amount:(NSUInteger)amount allObjects:(NSArray*)allObjects clb:(dashArrayInfoClb)clb forChain:(NSString*)chainNetwork;

@end
