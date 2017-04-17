//
//  DPRepositoryController.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/12/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DPRepositoryController.h"
#import <AFNetworking/AFNetworking.h>
#import "DPDataStore.h"

@implementation DPRepositoryController

-(void)addRepositoryForUser:(NSString*)user repoName:(NSString*)repoName branch:(NSString*)branch clb:(dashClb)clb {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@",user,repoName,branch] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if ([[responseObject objectForKey:@"object"] objectForKey:@"sha"]) {
            NSManagedObject * object = [[DPDataStore sharedInstance] branchNamed:branch onRepositoryURLPath:[NSString stringWithFormat:@"https://github.com/%@/%@.git",user,repoName]];
            [object setValue:[[responseObject objectForKey:@"object"] objectForKey:@"sha"] forKey:@"lastCommitSha"];
            [[DPDataStore sharedInstance] saveContext];
            return clb(YES,nil);
        } else {
            return clb(NO,@"Error fetching repository");
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        
        return clb(NO,@"Repository doesn't seem to exist");
    }];
    
}

-(void)updateBranchInfo:(NSManagedObject*)branch clb:(dashClb)clb {
    NSString * url = [branch valueForKeyPath:@"repository.url"];
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:url options:0 range:NSMakeRange(0, [url length])];
    if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
        NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
        if ([url.host isEqualToString:@"github.com"] && [url.pathExtension isEqualToString:@"git"] && url.pathComponents.count > 2) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            [manager GET:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@",url.pathComponents[1],[url.lastPathComponent stringByDeletingPathExtension],[branch valueForKey:@"name"]] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
                if ([[responseObject objectForKey:@"object"] objectForKey:@"sha"]) {
                    [branch setValue:[[responseObject objectForKey:@"object"] objectForKey:@"sha"] forKey:@"lastCommitSha"];
                    [[DPDataStore sharedInstance] saveContext];
                    return clb(YES,nil);
                } else {
                    return clb(NO,@"Error fetching repository");
                }
                
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                
                return clb(NO,@"Repository doesn't seem to exist");
            }];
        }
        
        

    }
    
}

#pragma mark - Singleton methods

+ (DPRepositoryController *)sharedInstance
{
    static DPRepositoryController *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPRepositoryController alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
