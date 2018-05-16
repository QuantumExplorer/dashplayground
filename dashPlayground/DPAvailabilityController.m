//
//  DPAvailabilityController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 15/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "DPAvailabilityController.h"
#import "DPMasternodeController.h"

@implementation DPAvailabilityController

-(NSMutableArray*)getAvailabilityRegions
{
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    NSMutableArray * availabilityRegions = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-regions"];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            for (NSDictionary * dictionary in output[@"Regions"]) {
                
                NSDictionary * rDict = [NSMutableDictionary dictionary];
                
                [rDict setValue:[dictionary valueForKey:@"RegionName"] forKey:@"RegionName"];
                [availabilityRegions addObject:rDict];
            }
        });
        
    });
    
    return availabilityRegions;
}

@end
