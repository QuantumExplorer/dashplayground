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
#import "DialogAlert.h"
#import "DPLocalNodeController.h"

@implementation DPRepositoryController

-(void)addRepositoryForUser:(NSString*)user repoName:(NSString*)repoName branch:(NSString*)branch clb:(dashClb)clb {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@",user,repoName,branch] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        if ([[responseObject objectForKey:@"object"] objectForKey:@"sha"]) {
            NSManagedObject * object = [[DPDataStore sharedInstance] branchNamed:branch onRepositoryURLPath:[NSString stringWithFormat:@"https://github.com/%@/%@.git",user,repoName]];
            [object setValue:[[responseObject objectForKey:@"object"] objectForKey:@"sha"] forKey:@"lastCommitSha"];
            [object setValue:@(0) forKey:@"repoType"];
            [[DPDataStore sharedInstance] saveContext];
            return clb(YES,nil);
        } else {
            return clb(NO,@"Error fetching repository");
        }
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        return clb(NO,@"Repository doesn't seem to exist");
    }];
    
}

-(void)addPrivateRepositoryForUser:(NSString*)user repoName:(NSString*)repoName branch:(NSString*)branch clb:(dashClb)clb {
    
    NSString *githubUsername = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github username" message:@"Please enter your Github username"];
    NSString *githubPassword = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github password" message:@"Please enter your Github password"];
    
    if([githubUsername length] == 0 || [githubPassword length] == 0) return;
    
    NSDictionary *repositoryDict =  [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@ -u %@:%@", user, repoName, branch, githubUsername, githubPassword] checkError:YES];
    
    if ([[repositoryDict objectForKey:@"object"] objectForKey:@"sha"]) {
        NSManagedObject * object = [[DPDataStore sharedInstance] branchNamed:branch onRepositoryURLPath:[NSString stringWithFormat:@"https://github.com/%@/%@.git",user,repoName]];
        [object setValue:[[repositoryDict objectForKey:@"object"] objectForKey:@"sha"] forKey:@"lastCommitSha"];
        [object setValue:@(1) forKey:@"repoType"];
        [[DPDataStore sharedInstance] saveContext];
        return clb(YES,nil);
    } else {
        return clb(NO,@"Error fetching repository");
    }
}

-(void)updateBranchInfo:(NSManagedObject*)branch clb:(dashClb)clb {
    
    NSUInteger repoType = [[branch valueForKey:@"repoType"] integerValue];
    
    NSString * url = [branch valueForKeyPath:@"repository.url"];
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:url options:0 range:NSMakeRange(0, [url length])];
    if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
        NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
        if ([url.host isEqualToString:@"github.com"] && [url.pathExtension isEqualToString:@"git"] && url.pathComponents.count > 2) {
            if(repoType == 0) {
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
            else {
                NSString *githubUsername = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github username" message:@"Please enter your Github username"];
                NSString *githubPassword = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github password" message:@"Please enter your Github password"];
                
                if([githubUsername length] == 0 || [githubPassword length] == 0) return;
                
                NSDictionary *repositoryDict =  [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@ -u %@:%@",url.pathComponents[1],[url.lastPathComponent stringByDeletingPathExtension],[branch valueForKey:@"name"], githubUsername, githubPassword] checkError:YES];
                
                if ([[repositoryDict objectForKey:@"object"] objectForKey:@"sha"]) {
                    [branch setValue:[[repositoryDict objectForKey:@"object"] objectForKey:@"sha"] forKey:@"lastCommitSha"];
                    [[DPDataStore sharedInstance] saveContext];
                    return clb(YES,nil);
                } else {
                    return clb(NO,@"Error fetching repository");
                }
            }
        }
    }
}

- (void)setAMIForRepository:(NSManagedObject*)repository clb:(dashClb)clb {
    NSString *amiID = [[DialogAlert sharedInstance] showAlertWithTextField:@"Set AMI for repository" message:@"Please fill in ami-id"];
    if([amiID length] == 0 || amiID == nil) return clb(NO, nil);
    
    [repository setValue:amiID forKey:@"amiId"];
    [[DPDataStore sharedInstance] saveContext];
    clb(YES, @"Successfully.");
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
