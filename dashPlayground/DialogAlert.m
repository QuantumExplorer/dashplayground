//
//  DialogAlert.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 12/3/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "DialogAlert.h"

static NSString *const selectInfoWarning = @"Please make sure you already select an instance.";

@implementation DialogAlert

-(NSAlert *)getFindPathAlert:(NSString *)filename exPath:(NSString *)exPath {
    
    NSString *strMessage = [NSString stringWithFormat: @"Launch path does not exist! (%@)", filename];
    NSString *strInformative = [NSString stringWithFormat: @"Please locate your launch path (ex. %@/%@)",exPath , filename];
    
    NSAlert *findPathAlert = [[NSAlert alloc] init];
    [findPathAlert addButtonWithTitle:@"Find"];
    [findPathAlert addButtonWithTitle:@"Cancel"];
    [findPathAlert setMessageText:strMessage];
    [findPathAlert setInformativeText:strInformative];
    
    return findPathAlert;
}

-(NSString *)getLaunchPath {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
//    [panel setAllowedFileTypes:@[@""]];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return nil;
    NSString *paths=[[panel URL] path];
    return paths;
}

-(NSArray *)getSSHLaunchPathAndName {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    //    [panel setAllowedFileTypes:@[@""]];
    if ([panel runModal] != NSFileHandlingPanelOKButton) return nil;
    
    NSURL *url = [NSURL URLWithString:[[panel URL] path]];
    NSString *fileName = [url lastPathComponent];
    
    NSString *filePath = [[panel URL] path];
    
    NSArray *sshFileInformation = @[fileName, filePath];
    
    return sshFileInformation;
}

-(void)showAlertWithOkButton:(NSString *)title message:(NSString *)message {
    
    NSString *strMessage = [NSString stringWithFormat: @"%@", title];
    NSString *strInformative = [NSString stringWithFormat: @"%@", message];
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"Ok"];
    [alert setMessageText:strMessage];
    [alert setInformativeText:strInformative];
    [alert runModal];
}

-(void)showWarningAlert:(NSString *)title message:(NSString *)message {
    
    NSString *strMessage = [NSString stringWithFormat: @"%@", title];
    NSString *strInformative = [NSString stringWithFormat: @"%@", message];
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"Ok"];
    [alert setMessageText:strMessage];
    [alert setInformativeText:strInformative];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

-(NSAlert *)showAlertWithYesNoButton:(NSString *)title message:(NSString *)message {
    
    NSString *strMessage = [NSString stringWithFormat: @"%@", title];
    NSString *strInformative = [NSString stringWithFormat: @"%@", message];
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert setMessageText:strMessage];
    [alert setInformativeText:strInformative];
    
    return alert;
}

-(NSString *)showAlertWithTextField:(NSString *)title message:(NSString*)message {
    NSString *strMessage = [NSString stringWithFormat: @"%@", title];
    NSString *strInformative = [NSString stringWithFormat: @"%@", message];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    
    NSAlert *alert = [[NSAlert alloc]init];
    [alert addButtonWithTitle:@"Ok"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:strMessage];
    [alert setInformativeText:strInformative];
    [alert setAccessoryView:input];
    
    [alert runModal];
    
    return [input stringValue];
}

#pragma mark - Singleton methods

+ (DialogAlert *)sharedInstance
{
    static DialogAlert *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DialogAlert alloc] init];
        
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

@end
