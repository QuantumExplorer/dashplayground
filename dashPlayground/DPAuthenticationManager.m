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
#define NPM_CREDENTIALS @"NPM_CREDENTIALS"
#define SPORK_CREDENTIALS @"SPORK_CREDENTIALS"
#define GITHUB_ACCESS_TOKEN @"GITHUB_ACCESS_TOKEN"
#define NPM_TOKEN @"NPM_TOKEN"
#define GITHUB_SSH_PATH @"GITHUB_SSH_PATH"
#define DEFAULT_AUTHENTICATION_TIME_MINUTES 30

@interface DPAuthenticationManager()

@property(nonatomic,assign) NSTimeInterval authenticatedTillTimestamp;
@property(nonatomic,strong) NSString * tempCredentialToken;
@property(nonatomic,strong) NSData * tempCredentialData;
@property(nonatomic,strong) NSString * tempCredentialNPMToken;
@property(nonatomic,strong) NSData * tempCredentialNPMData;
@property(nonatomic,strong) NSString * tempCredentialSporkToken;
@property(nonatomic,strong) NSData * tempCredentialSporkData;

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
        self.tempCredentialNPMData = nil;
        self.tempCredentialNPMToken = nil;
        self.tempCredentialSporkData = nil;
        self.tempCredentialSporkToken = nil;
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

-(BOOL)hasNPMCredentials {
    NSError * error;
    return hasKeychainData(NPM_CREDENTIALS, &error);
}

-(BOOL)hasSporkCredentials {
    NSError * error;
    return hasKeychainData(SPORK_CREDENTIALS, &error);
}

-(void)requestGithubCredentialsWithClb:(dashCredentialsClb)clb {
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSString * username = [[DialogAlert sharedInstance] showAlertWithTextField:@"Github username" message:@"Please enter your Github username" placeHolder:@""];
            NSString * password = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Github password" message:@"Please enter your Github password"];
            NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter a passcode"];
            NSDictionary * credentials = @{GITHUB_USERNAME_KEY:username,GITHUB_PASSWORD_KEY:password};
            [self encodeCredentials:credentials withPasscode:passcode];
            [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
            clb(YES,username,password);
        }
    });
}

-(void)requestSporkCredentialsWithClb:(dashCredentialsClb)clb {
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSString * address = [[DialogAlert sharedInstance] showAlertWithTextField:@"Spork Address" message:@"Please enter your Spork address" placeHolder:@""];
            NSString * privateKey = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Spork Private Key" message:@"Please enter your Spork private key"];
            NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter a passcode"];
            NSDictionary * credentials = @{SPORK_ADDRESS_KEY:address,SPORK_PRIVATE_KEY:privateKey};
            [self encodeSporkCredentials:credentials withPasscode:passcode];
            [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
            clb(YES,address,privateKey);
        }
    });
}

-(void)requestNPMTokenWithClb:(dashMessageClb)clb {
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSString * npmToken = [[DialogAlert sharedInstance] showAlertWithTextField:@"NPM token" message:@"Please enter your NPM token" placeHolder:@""];
            NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter a passcode"];
            NSDictionary * credentials = @{NPM_TOKEN:npmToken};
            [self encodeNPMCredentials:credentials withPasscode:passcode];
            [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
            clb(YES,npmToken);
        }
    });
}

-(void)authenticateWithClb:(dashCredentialsClb)clb {
    @autoreleasepool {
        if ([self isAuthenticated] && self.tempCredentialData) {
            NSError * error = nil;
            NSData * encryptedData = self.tempCredentialData;
            NSData *data = [RNDecryptor decryptData:encryptedData withPassword:self.tempCredentialToken error:&error];
            if (error) {
                [self authenticateForMinutes:-1];
                [self authenticateWithClb:clb];
                return;
            }
            NSDictionary * credentials = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            clb(YES,[credentials objectForKey:GITHUB_USERNAME_KEY],[credentials objectForKey:GITHUB_PASSWORD_KEY]);
            return;
        }
        if (![self hasGithubCredentials]) {
            [self requestGithubCredentialsWithClb:clb];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter your passcode"];
                NSDictionary * credentials = [self credentialsDecodedWithPasscode:passcode];
                if (![credentials objectForKey:GITHUB_USERNAME_KEY] || ![credentials objectForKey:GITHUB_PASSWORD_KEY]) {
                    [self requestGithubCredentialsWithClb:clb];
                    return;
                }
                self.tempCredentialToken = [self randomPassword];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credentials];
                NSError *error;
                self.tempCredentialData = [RNEncryptor encryptData:data
                                                      withSettings:kRNCryptorAES256Settings
                                                          password:self.tempCredentialToken
                                                             error:&error];
                [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
                clb(YES,[credentials objectForKey:GITHUB_USERNAME_KEY],[credentials objectForKey:GITHUB_PASSWORD_KEY]);
            });
        }
    }
}

-(void)authenticateNPMWithClb:(dashMessageClb)clb {
    @autoreleasepool {
        if ([self isAuthenticated]) {
            NSError * error = nil;
            NSData * encryptedData = self.tempCredentialNPMData;
            NSData *data = [RNDecryptor decryptData:encryptedData withPassword:self.tempCredentialNPMToken error:&error];
            if (error) {
                [self authenticateForMinutes:-1];
                [self authenticateNPMWithClb:clb];
                return;
            }
            NSDictionary * credentials = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            clb(YES,[credentials objectForKey:NPM_TOKEN]);
            return;
        }
        if (![self hasNPMCredentials]) {
            [self requestNPMTokenWithClb:clb];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter your passcode"];
                NSDictionary * credentials = [self npmCredentialsDecodedWithPasscode:passcode];
                self.tempCredentialNPMToken = [self randomPassword];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credentials];
                NSError *error;
                self.tempCredentialNPMData = [RNEncryptor encryptData:data
                                                         withSettings:kRNCryptorAES256Settings
                                                             password:self.tempCredentialNPMToken
                                                                error:&error];
                [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
                clb(YES,[credentials objectForKey:NPM_TOKEN]);
            });
        }
    }
}

-(void)authenticateSporkWithClb:(dashCredentialsClb)clb {
    @autoreleasepool {
        if ([self isAuthenticated]) {
            NSError * error = nil;
            NSData * encryptedData = self.tempCredentialSporkData;
            NSData *data = [RNDecryptor decryptData:encryptedData withPassword:self.tempCredentialSporkToken error:&error];
            if (error) {
                [self authenticateForMinutes:-1];
                [self authenticateSporkWithClb:clb];
                return;
            }
            NSDictionary * credentials = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            clb(YES,[credentials objectForKey:SPORK_ADDRESS_KEY],[credentials objectForKey:SPORK_PRIVATE_KEY]);
            return;
        }
        if (![self hasSporkCredentials]) {
            [self requestSporkCredentialsWithClb:clb];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString * passcode = [[DialogAlert sharedInstance] showAlertWithSecureTextField:@"Encryption passcode" message:@"Please enter your passcode"];
                NSDictionary * credentials = [self sporkCredentialsDecodedWithPasscode:passcode];
                self.tempCredentialSporkToken = [self randomPassword];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credentials];
                NSError *error;
                self.tempCredentialSporkData = [RNEncryptor encryptData:data
                                                         withSettings:kRNCryptorAES256Settings
                                                             password:self.tempCredentialSporkToken
                                                                error:&error];
                [self authenticateForMinutes:DEFAULT_AUTHENTICATION_TIME_MINUTES];
                clb(YES,[credentials objectForKey:SPORK_ADDRESS_KEY],[credentials objectForKey:SPORK_PRIVATE_KEY]);
            });
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

-(void)encodeNPMCredentials:(NSDictionary*)dictionary withPasscode:(NSString*)passcode {
    if ([passcode length] < 4) return;
    @autoreleasepool {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
        NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:data
                                            withSettings:kRNCryptorAES256Settings
                                                password:passcode
                                                   error:&error];
        setKeychainData(encryptedData, NPM_CREDENTIALS, YES);
    }
}

-(void)encodeSporkCredentials:(NSDictionary*)dictionary withPasscode:(NSString*)passcode {
    if ([passcode length] < 4) return;
    @autoreleasepool {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
        NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:data
                                            withSettings:kRNCryptorAES256Settings
                                                password:passcode
                                                   error:&error];
        setKeychainData(encryptedData, SPORK_CREDENTIALS, YES);
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

-(NSDictionary*)npmCredentialsDecodedWithPasscode:(NSString*)passcode {
    NSError * error = nil;
    NSData * encryptedData = getKeychainData(NPM_CREDENTIALS, &error);
    if (error) return nil;
    NSData *data = [RNDecryptor decryptData:encryptedData withPassword:passcode error:&error];
    if (error) return nil;
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

-(NSDictionary*)sporkCredentialsDecodedWithPasscode:(NSString*)passcode {
    NSError * error = nil;
    NSData * encryptedData = getKeychainData(SPORK_CREDENTIALS, &error);
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
