//
//  AppDelegate.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "AppDelegate.h"
#import "DPMasternodeController.h"
#import "DPDataStore.h"
#import "MasternodeStateTransformer.h"
#import "SentinelStateTransformer.h"
#import "DialogAlert.h"
#import "DPMasternodeController.h"
#import "VolumeViewController.h"
#import "RepositoriesModalViewController.h"
#import "RepositoriesViewController.h"
#import <NMSSH/NMSSH.h>
#import "SshConnection.h"
#import "DPMasternodeController.h"
#import "InstanceStateTransformer.h"
#import "DPChainSelectionController.h"
#import "PreferenceWindowController.h"
#import "DPVersioningController.h"
#import "GithubAPI.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
//    Toey, adding some code here to test somethong more easier.
    
//    NSLog(@"%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"chainNetworkName"]);
    
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"securityGroupId"];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"subnetID"];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"keyName"];
    
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"masterNodePath"];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"dashDPath"];
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"dashCliPath"];
    
    //end
    
    NSArray * checkingMasternodes = [[DPDataStore sharedInstance] allMasternodes];
    for (NSManagedObject * masternode in checkingMasternodes) {
        
//        if ([[masternode valueForKey:@"chainNetwork"] rangeOfString:@"devnet"].location != NSNotFound
//            && [[masternode valueForKey:@"instanceState"] integerValue] == InstanceState_Running) {
//            [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
//                [sshSession.channel uploadFile:@"/Users/nattapon17/Desktop/Dash/dash-cli" to:@"/home/ubuntu/src/dash/src/dash-cli"];
//                [sshSession.channel uploadFile:@"/Users/nattapon17/Desktop/Dash/dashd" to:@"/home/ubuntu/src/dash/src/dashd"];
//            }];
//        }
        
        if(![masternode valueForKey:@"publicIP"] || [[masternode valueForKey:@"instanceState"] integerValue] == InstanceState_Shutting_Down) continue;

        if ([[masternode valueForKey:@"masternodeState"] integerValue] == MasternodeState_Checking) {
            [[DPMasternodeController sharedInstance] checkMasternode:masternode];
        }
        else if ([[masternode valueForKey:@"masternodeState"] integerValue] == MasternodeState_SettingUp) {
            if([[masternode valueForKey:@"instanceState"] integerValue] == InstanceState_Terminated) return;
            [[SshConnection sharedInstance] sshInWithKeyPath:[[DPMasternodeController sharedInstance] sshPath] masternodeIp:[masternode valueForKey:@"publicIP"] openShell:NO clb:^(BOOL success, NSString *message, NMSSHSession *sshSession) {
                if (success) {
                    [[DPMasternodeController sharedInstance] checkMasternodeIsProperlyInstalled:masternode onSSH:sshSession];
                }
            }];
        }
        else {
            //[[DPMasternodeController sharedInstance] checkSentinel:masternode];
        }
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

#pragma mark - Core Data stack

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;


-(NSArray *)executeFetchRequest:(NSFetchRequest*)request inContext:(NSManagedObjectContext*)context error:(__autoreleasing NSError**)error {
    if ([NSThread isMainThread]) {
        //LGLog(@"executing fetch request on main thread");
#if LOG_BACKGROUND_CALLS
        NSDate * date = [NSDate date];
#endif
        id returnData = [context executeFetchRequest:request error:error];
#if LOG_BACKGROUND_CALLS
        NSTimeInterval thisInterval = [[NSDate date] timeIntervalSinceDate:date];
        totalTime += thisInterval;
#endif
        //LGLog(@"took %.5f (%.5f)",thisInterval,totalTime);
        return returnData;
        
    } else {
#if LOG_BACKGROUND_CALLS
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            mDict = [NSMutableDictionary dictionary];
        });
        NSArray * callStackSymbols = [NSThread callStackSymbols];
        NSString * level = [callStackSymbols objectAtIndex:LOG_LEVEL];
        NSError *error = NULL;
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[[^\\].]*\\]" options:NSRegularExpressionCaseInsensitive error:&error];
        
        
        [regex enumerateMatchesInString:level options:0 range:NSMakeRange(0, [level length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            
            // detect
            NSString *insideString = [level substringWithRange:[match range]];
            if ([mDict objectForKey:insideString]) {
                [mDict setObject:@([[mDict objectForKey:insideString] integerValue] + 1) forKey:insideString];
            } else {
                [mDict setObject:@(1) forKey:insideString];
            }
            //print
            NSLog(@"%@",mDict);
            
        }];
#endif
        __block NSError *theError = nil;
        __block NSArray *rArray;
        //NSThread * thread = [NSThread currentThread];
        [context performBlockAndWait:^{
            //NSThread * blockThread = [NSThread currentThread];
            //NSAssert(blockThread == thread, @"should be same threads");
            rArray = [context executeFetchRequest:request error:&theError];
        }];
        return rArray;
    }
}


- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = _managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)saveContext:(NSManagedObjectContext*)managedObjectContext
{
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "org.dashfoundation.ddd" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"org.dashfoundation.PlaygroundModel"];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PlaygroundModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties) {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    } else if ([error code] == NSFileReadNoSuchFileError) {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error) {
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *url = [applicationDocumentsDirectory URLByAppendingPathComponent:@"PlaygroundModel 3.storedata"];
        if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                /*
                 Typical reasons for an error here include:
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                coordinator = nil;
            }
        }
        _persistentStoreCoordinator = coordinator;
    }
    
    if (shouldFail || error) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error) {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

#pragma mark - Core Data Saving and Undo support

- (IBAction)saveAction:(id)sender {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    NSManagedObjectContext *context = self.managedObjectContext;
    
    if (![context commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    NSError *error = nil;
    if (context.hasChanges && ![context save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Save changes in the application's managed object context before the application terminates.
    NSManagedObjectContext *context = _managedObjectContext;
    
    if (!context) {
        return NSTerminateNow;
    }
    
    if (![context commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (!context.hasChanges) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertSecondButtonReturn) {
            return NSTerminateCancel;
        }
    }
    
    return NSTerminateNow;
}

- (IBAction)openPreference:(id)sender {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Preference" bundle:nil]; // get a reference to the storyboard
    PreferenceWindowController *myPreference = [storyBoard instantiateControllerWithIdentifier:@"mainWindow"]; // instantiate your window controller
    [myPreference showWindow:self]; // show the window
}

@end
