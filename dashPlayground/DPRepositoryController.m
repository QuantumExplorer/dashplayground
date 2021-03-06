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
#import "Branch+CoreDataClass.h"
#import "NSData+Security.h"
#import "DPAuthenticationManager.h"
#import "Repository+CoreDataClass.h"
#import "Branch+CoreDataClass.h"

@implementation DPRepositoryController

-(void)addRepository:(NSString*)repositoryLocation forProject:(DPRepositoryProject)project forUser:(NSString*)user branchName:(NSString*)branchName isPrivate:(BOOL)isPrivate clb:(dashMessageClb)clb {
    if (isPrivate) {
        [self addPrivateRepository:repositoryLocation forUser:user forProject:project branchName:branchName clb:clb];
    } else {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        [manager GET:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@",user,repositoryLocation,branchName] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            if ([[responseObject objectForKey:@"object"] objectForKey:@"sha"]) {
                Repository * repository = [[DPDataStore sharedInstance] repositoryNamed:repositoryLocation forOwner:user inProject:project onRepositoryURLPath:[NSString stringWithFormat:@"https://github.com/%@/%@.git",user,repositoryLocation]];
                Branch * branch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                branch.lastCommitHash = [[responseObject objectForKey:@"object"] objectForKey:@"sha"];
                branch.repository.isPrivate = isPrivate;
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

-(void)addPrivateRepository:(NSString*)repositoryLocation forUser:(NSString*)user forProject:(DPRepositoryProject)project branchName:(NSString*)branchName clb:(dashMessageClb)clb {
    [[DPAuthenticationManager sharedInstance] authenticateWithClb:^(BOOL authenticated, NSString *githubUsername, NSString *githubPassword) {
        if (authenticated) {
            NSDictionary *repositoryDict =  [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@ -u %@:%@", user, repositoryLocation, branchName, githubUsername, githubPassword] checkError:YES];
            
            if ([[repositoryDict objectForKey:@"object"] objectForKey:@"sha"]) {
                Repository * repository = [[DPDataStore sharedInstance] repositoryNamed:repositoryLocation forOwner:user inProject:project onRepositoryURLPath:[NSString stringWithFormat:@"https://github.com/%@/%@.git",user,repositoryLocation]];
                Branch * branch = [[DPDataStore sharedInstance] branchNamed:branchName inRepository:repository];
                branch.lastCommitHash = [[repositoryDict objectForKey:@"object"] objectForKey:@"sha"];
                repository.isPrivate = 1;
                [[DPDataStore sharedInstance] saveContext];
                return clb(YES,nil);
            } else {
                return clb(NO,@"Error fetching repository");
            }
        }
    }];
    
    
}

-(void)updateBranchInfo:(Branch*)branch clb:(dashMessageClb)clb {
    Repository * repository = branch.repository;
    NSUInteger isPrivate = repository.isPrivate;
    
    NSString * url = branch.repository.url;
    NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray *matches = [linkDetector matchesInString:url options:0 range:NSMakeRange(0, [url length])];
    if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
        NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
        if ([url.host isEqualToString:@"github.com"] && [url.pathExtension isEqualToString:@"git"] && url.pathComponents.count > 2) {
            if(!isPrivate) {
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                [manager GET:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@",repository.owner,repository.name,branch.name] parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
                    if ([[responseObject objectForKey:@"object"] objectForKey:@"sha"]) {
                        branch.lastCommitHash = [[responseObject objectForKey:@"object"] objectForKey:@"sha"];
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
                [[DPAuthenticationManager sharedInstance] authenticateWithClb:^(BOOL authenticated, NSString *githubUsername, NSString *githubPassword) {
                    if (!authenticated) return;
                    NSDictionary *repositoryDict =  [[DPLocalNodeController sharedInstance] runCurlCommandJSON:[NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/git/refs/heads/%@ -u %@:%@",url.pathComponents[1],[url.lastPathComponent stringByDeletingPathExtension],[branch valueForKey:@"name"], githubUsername, githubPassword] checkError:YES];
                    
                    if ([[repositoryDict objectForKey:@"object"] objectForKey:@"sha"]) {
                        branch.lastCommitHash = [[repositoryDict objectForKey:@"object"] objectForKey:@"sha"];
                        [[DPDataStore sharedInstance] saveContext];
                        return clb(YES,nil);
                    } else {
                        return clb(NO,@"Error fetching repository");
                    }
                }];
            }
        }
    }
}

- (void)setAMIForRepository:(NSManagedObject*)repository clb:(dashMessageClb)clb {
    NSString *amiID = [[DialogAlert sharedInstance] showAlertWithTextField:@"Set AMI for repository" message:@"Please fill in ami-id" placeHolder:@""];
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
