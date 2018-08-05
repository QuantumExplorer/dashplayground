//
//  DialogAlert.h
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 12/3/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DialogAlert : NSAlert

+(DialogAlert*)sharedInstance;

-(NSAlert *)getFindPathAlert:(NSString *)filename exPath:(NSString *)exPath;
-(NSString *)getLaunchPath;
-(NSArray *)getSSHLaunchPathAndName;

-(void)showAlertWithOkButton:(NSString *)title message:(NSString *)message;
-(NSAlert *)showAlertWithYesNoButton:(NSString *)title message:(NSString *)message;
-(void)showWarningAlert:(NSString *)title message:(NSString *)message;
-(NSString *)showAlertWithTextField:(NSString *)title message:(NSString*)message placeHolder:(NSString*)placeHolderStr;
-(NSString *)showAlertWithSecureTextField:(NSString *)title message:(NSString*)message;

@end

