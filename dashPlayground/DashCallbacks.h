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
typedef void (^dashErrorClb)(BOOL success,NSError* error);
typedef void (^dashClbWithError)(BOOL success,NSString * message,NSError* error);
typedef void (^dashInfoClb)(BOOL success,NSDictionary * object,NSString* errorMessage);
typedef void (^dashBoolClb)(BOOL success,BOOL value,NSString* errorMessage);
typedef void (^dashActiveClb)(BOOL active);
typedef void (^dashInstalledClb)(BOOL success,BOOL installed);
typedef void (^dashSyncClb)(BOOL active);
typedef void (^dashCredentialsClb)(BOOL authenticated,NSString* userName,NSString* password);
typedef void (^dashMutaArrayInfoClb)(BOOL success,NSMutableArray * object);
typedef void (^dashDictInfoClb)(BOOL success,NSDictionary * dictionary);
typedef void (^dashSSHClb)(BOOL success,NSString * message, NMSSHSession *sshSession);
typedef void (^dashSuccessInfo)(BOOL success,NSString * message,BOOL isFinished);
typedef void (^dashDataClb)(BOOL success,NSString * message,NSData *data);
typedef void (^dashArrayClb)(BOOL success,NSArray *array);

#endif /* DashCallbacks_h */
