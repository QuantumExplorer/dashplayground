//
//  PreferenceData.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 29/4/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#ifndef PreferenceData_h
#define PreferenceData_h


#endif /* PreferenceData_h */

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PreferenceData : NSObject

+(PreferenceData*)sharedInstance;

-(NSString*)getSecurityGroupId;
-(void)setSecurityGroupId:(NSString*)groupID;

-(NSString*)getSubnetID;
-(void)setSubnetID:(NSString*)subnetID;

-(NSString*)getKeyName;
-(void)setKeyName:(NSString*)keyName;

@end
