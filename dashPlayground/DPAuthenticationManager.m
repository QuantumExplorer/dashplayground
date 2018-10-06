//
//  DPAuthenticationManager.m
//  dashPlayground
//
//  Created by Sam Westrich on 10/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "DPAuthenticationManager.h"
#import <RNCryptor-objc/RNCryptor.h>
#import <RNCryptor-objc/RNEncryptor.h>
#import <RNCryptor-objc/RNDecryptor.h>
#import "NSData+Security.h"
#import "DialogAlert.h"

#define GITHUB_CREDENTIALS @"GITHUB_CREDENTIALS"
#define GITHUB_ACCESS_TOKEN @"GITHUB_ACCESS_TOKEN"
#define GITHUB_SSH_PATH @"GITHUB_SSH_PATH"
#define DEFAULT_AUTHENTICATION_TIME_MINUTES 30

@interface DPAuthenticationManager()

@property(nonatomic,assign) NSTimeInterval authenticatedTillTimestamp;
@property(nonatomic,strong) NSString * tempCredentialToken;
@property(nonatomic,strong) NSData * tempCredentialData;

@end

@implementation DPAuthenticationManager

-(NSString*)randomPassword {
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

-(BOOL)isAuthenticated {
    if ([[NSDate date] timeIntervalSince1970] < self.authenticatedTillTimestamp) {
        return TRUE;
    } else {
        self.tempCredentialToken = nil;
        self.tempCredentialData = nil;
        return FALSE;
    }
}

-(void)authenticateForMinutes:(uint32)minutes {
    self.authenticatedTillTimestamp = [[NSDate date] timeIntervalSince1970] + minutes*60;
}

-(BOOL)hasGithubCredentials {
    NSError * error;
    return hasKeychainData(GITHUB_CREDENTIALS, &error);
}

-(void)requestGithubCredentialsWithClb:(dashCredentialsClb)clb {
    @autoreleasepool {
    NSString * username = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github username" message:@"Please enter your Github username" placeHolder:@""];
    NSString * password = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github password" message:@"Please enter your Github password"];
    NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter a passcode"];
    NSDictionary * credentials = @{GITHUB_USERNAME_KEY:username,GITHUB_PASSWORD_KEY:password};
    [self encodeCredentials:credentials withPasscode:passcode];
    [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
    clb(YES,username,password);
    }
}

-(void)authenticateWithClb:(dashCredentialsClb)clb {
    @autoreleasepool {
    if ([self isAuthenticated]) {
        NSError * error = nil;
        NSData * encryptedData = self.tempCredentialData;
        if (error) {
            clb(NO,nil,nil);
            return;
        }
        NSData *data = [RNDecryptor decryptData:encryptedData withPassword:self.tempCredentialToken error:&error];
        if (error) {
            clb(NO,nil,nil);
            return;
        }
        NSDictionary * credentials = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        clb(YES,[credentials objectForKey:GITHUB_USERNAME_KEY],[credentials objectForKey:GITHUB_PASSWORD_KEY]);
        return;
    }
    if (![self hasGithubCredentials]) {
        [self requestGithubCredentialsWithClb:clb];
    } else {
        NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter your passcode"];
        NSDictionary * credentials = [self credentialsDecodedWithPasscode:passcode];
        self.tempCredentialToken = [self randomPassword];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credentials];
        NSError *error;
        self.tempCredentialData = [RNEncryptor encryptData:data
                                            withSettings:kRNCryptorAES256Settings
                                                password:self.tempCredentialToken
                                                   error:&error];
        [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
        clb(YES,[credentials objectForKey:GITHUB_USERNAME_KEY],[credentials objectForKey:GITHUB_PASSWORD_KEY]);
    }
    }
}

-(void)encodeCredentials:(NSDictionary*)dictionary withPasscode:(NSString*)passcode {
    if ([passcode length] < 4) return;
    @autoreleasepool {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
        NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:data
                                            withSettings:kRNCryptorAES256Settings
                                                password:passcode
                                                   error:&error];
        setKeychainData(encryptedData, GITHUB_CREDENTIALS, YES);
    }
}

-(NSDictionary*)credentialsDecodedWithPasscode:(NSString*)passcode {
    NSError * error = nil;
    NSData * encryptedData = getKeychainData(GITHUB_CREDENTIALS, &error);
    if (error) return nil;
    NSData *data = [RNDecryptor decryptData:encryptedData withPassword:passcode error:&error];
    if (error) return nil;
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(void)setGithubAccessToken:(NSString *)githubAccessToken {
    setKeychainString(githubAccessToken, GITHUB_ACCESS_TOKEN, YES);
}

-(NSString*)getGithubAccessToken {
    NSError * error = nil;
    NSString * string = getKeychainString(GITHUB_ACCESS_TOKEN, &error);
    if (!error) return string;
    return @"";
}

-(void)setGithubSSHPath:(NSString *)githubSshPath {
    [[NSUserDefaults standardUserDefaults] setObject:githubSshPath forKey:GITHUB_SSH_PATH];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSString*)getGithubSSHPath {
    return [[NSUserDefaults standardUserDefaults] stringForKey:GITHUB_SSH_PATH];
}


#pragma mark -
#pragma mark Singleton methods

+ (DPAuthenticationManager *)sharedInstance
{
    static DPAuthenticationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DPAuthenticationManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
