//
//  DPAuthenticationManager.h
//  dashPlayground
//
//  Created by Sam Westrich on 10/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DashCallbacks.h"

NS_ASSUME_NONNULL_BEGIN

#define GITHUB_USERNAME_KEY @"GITHUB_USERNAME_KEY"
#define GITHUB_PASSWORD_KEY @"GITHUB_PASSWORD_KEY"

@interface DPAuthenticationManager : NSObject

+(DPAuthenticationManager*)sharedInstance;

#pragma mark - Security

-(void)authenticateWithClb:(dashCredentialsClb)clb;

-(void)encodeCredentials:(NSDictionary*)dictionary withPasscode:(NSString*)passcode;

-(NSDictionary*)credentialsDecodedWithPasscode:(NSString*)passcode;

-(NSString*)getGithubAccessToken;

-(void)setGithubAccessToken:(NSString *)githubAccessToken;

-(NSString*)getGithubSSHPath;

-(void)setGithubSSHPath:(NSString *)githubSshPath;

@end

NS_ASSUME_NONNULL_END
