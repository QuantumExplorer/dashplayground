//
//  DashCallbacks.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/12/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#ifndef DashCallbacks_h
#define DashCallbacks_h

typedef void (^dashClb)(BOOL success,NSString * message);
typedef void (^dashInfoClb)(BOOL success,NSDictionary * object,NSString* errorMessage);
typedef void (^dashBoolClb)(BOOL success,BOOL value,NSString* errorMessage);
typedef void (^dashActiveClb)(BOOL active);
typedef void (^dashSyncClb)(BOOL active);

#endif /* DashCallbacks_h */
