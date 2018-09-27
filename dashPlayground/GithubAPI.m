//
//  GithubAPI.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 17/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "GithubAPI.h"
#import "DPLocalNodeController.h"
#import "DPDataStore.h"
#import "DialogAlert.h"

@implementation GithubAPI

- (NSDictionary*)getSingleCommitDictionaryData:(NSString*)owner repository:(NSString*)repository commit:(NSString*)commitSha {
    //ex. https://api.github.com/repos/dashevo/dash/commits/73ed410715e70d43214400cfdce0186ad31468be -u 9455f27d248484a41f709b785165474680e3feb7:x-oauth-basic
    
    if([[[DPDataStore sharedInstance] getGithubAccessToken] length] == 0) {
        NSString *accessToken = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github access token" message:@"Please input your github access token."];
        
        if([accessToken length] == 0) {
            return nil;
        }
        else {
            [[DPDataStore sharedInstance] setGithubAccessToken:accessToken];
        }
    }
    
    NSString *curlCommand = [NSString stringWithFormat:@"https://api.github.com/repos/%@/%@/commits/%@ -u %@:x-oauth-basic", owner, repository, commitSha, [[DPDataStore sharedInstance] getGithubAccessToken]];
    
    NSDictionary *dict =  [[DPLocalNodeController sharedInstance] runCurlCommandJSON:curlCommand checkError:YES];
    
    return dict;
}

#pragma mark - Singleton methods

+ (GithubAPI *)sharedInstance
{
    static GithubAPI *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[GithubAPI alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
