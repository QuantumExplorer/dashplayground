//
//  PreferenceData.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 29/4/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreferenceData.h"

#define SECURITYGRID @"securityGroupId"
#define SUBNETID @"subnetID"
#define KEYNAME @"keyName"
#define AWSPATH @"awsPath"

@interface PreferenceData ()


@end

@implementation PreferenceData

-(NSString*)getSecurityGroupId {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:SECURITYGRID];
}

-(void)setSecurityGroupId:(NSString*)groupID {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:groupID forKey:SECURITYGRID];
}

-(NSString*)getSubnetID {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:SUBNETID];
}

-(void)setSubnetID:(NSString*)subnetID {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:subnetID forKey:SUBNETID];
}

-(NSString*)getKeyName {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:KEYNAME];
}

-(void)setKeyName:(NSString*)keyName {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:keyName forKey:KEYNAME];
}

-(NSString*)getAWSPath {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    return [standardUserDefaults stringForKey:AWSPATH];
}

-(void)setAWSPath:(NSString*)path {
    NSUserDefaults * standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setObject:path forKey:AWSPATH];
}

#pragma mark - Singleton methods

+ (PreferenceData *)sharedInstance
{
    static PreferenceData *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[PreferenceData alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
