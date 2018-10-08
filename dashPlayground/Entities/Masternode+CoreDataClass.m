//
//  Masternode+CoreDataClass.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//
//

#import "Masternode+CoreDataClass.h"

@implementation Masternode

-(Branch*)branchForProject:(DPRepositoryProject)project {
    switch (project) {
        case DPRepositoryProject_Core:
            return self.coreBranch;
        case DPRepositoryProject_Sentinel:
            return self.sentinelBranch;
        case DPRepositoryProject_Dapi:
            return self.dapiBranch;
        case DPRepositoryProject_Drive:
            return self.driveBranch;
        case DPRepositoryProject_Insight:
            return self.insightBranch;
        default:
            return nil;
    }
}

@end
