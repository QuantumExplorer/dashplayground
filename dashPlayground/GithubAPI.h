//
//  GithubAPI.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 17/8/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GithubAPI : NSObject

+(GithubAPI*)sharedInstance;

- (NSDictionary*)getSingleCommitDictionaryData:(NSString*)owner repository:(NSString*)repo commit:(NSString*)commitSha;

@end
