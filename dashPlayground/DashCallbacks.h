//
//  DashCallbacks.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/12/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#ifndef DashCallbacks_h
#define DashCallbacks_h

#import <NMSSH/NMSSH.h>

typedef void (^dashClb)(BOOL success,NSString * message);
typedef void (^dashInfoClb)(BOOL success,NSDictionary * object,NSString* errorMessage);
typedef void (^dashBoolClb)(BOOL success,BOOL value,NSString* errorMessage);
typedef void (^dashActiveClb)(BOOL active);
typedef void (^dashSyncClb)(BOOL active);
typedef void (^dashArrayInfoClb)(BOOL success,NSMutableArray * object);
typedef void (^dashDictInfoClb)(BOOL success,NSDictionary * object);
typedef void (^dashSshClb)(BOOL success,NSString * message, NMSSHSession *sshSession);
typedef void (^dashSuccessInfo)(BOOL success,NSString * message,BOOL isFinished);

#endif /* DashCallbacks_h */
