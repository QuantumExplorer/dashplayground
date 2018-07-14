//
//  NetworkViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 25/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "NetworkViewController.h"
#import "ConsoleEventArray.h"
#import "DPMasternodeController.h"
#import "DPNetworkController.h"
#import "DPDataStore.h"
#import "DebugTypeTransformer.h"

@interface NetworkViewController ()

@property (strong) IBOutlet NSPopUpButton *dataTypeItemsButton;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTableView *tableView;

@property (strong) ConsoleEventArray * consoleEvents;
@property (strong) IBOutlet NSTextView *consoleTextField;
@property (strong) IBOutlet NSTextView *debugLogField;

@property (nonatomic,strong) NSString * currentDebugLog;

@end

@implementation NetworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    [self setUpConsole];
    [self initializeTable];
    [self createLogDataType];
}

- (void)initializeTable {
    [self addStringEvent:@"Initializing instances from AWS."];
    NSArray * masternodesArray = [[DPDataStore sharedInstance] allMasternodes];
    for (NSManagedObject * masternode in masternodesArray) {
        [self showTableContent:masternode];
        [[DPMasternodeController sharedInstance] checkMasternode:masternode];
    }
}

- (void)createLogDataType {
    [self.dataTypeItemsButton removeAllItems];
    [self.dataTypeItemsButton addItemsWithTitles:[[DebugTypeTransformer sharedInstance] getAllDataTypes]];
}

-(void)showTableContent:(NSManagedObject*)object
{
//    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] initWithDictionary:object];
//    [mutableDictionary setObject:@"0" forKey:@"selected"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.arrayController addObject:object];
        
        [self.arrayController rearrangeObjects];
        
        //        NSArray *array = [self.arrayController arrangedObjects];
        //        NSUInteger row = [array indexOfObjectIdenticalTo:dictionary];
        
        //        [self.unspentTable editColumn:0 row:row withEvent:nil select:YES];
    });
    
}

-(void)setUpConsole {
    self.consoleEvents = [[ConsoleEventArray alloc] init];
}

- (IBAction)pressDebugLog:(id)sender {
    NSInteger row = self.tableView.selectedRow;
    if (row == -1) return;

    self.debugLogField.string = @" ";
    NSManagedObject * object = [self.arrayController.arrangedObjects objectAtIndex:row];
    if(![object valueForKey:@"publicIP"]) return;

    
    [self addStringEvent:[NSString stringWithFormat:@"Downloading debug.log file from %@.", [object valueForKey:@"publicIP"]]];
    [[DPNetworkController sharedInstance] getDebugLogFileFromMasternode:object clb:^(BOOL success, NSString *message) {
        if(success == YES) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.debugLogField.string = message;
                self.currentDebugLog = message;
            });
        }
        else {
            [self addStringEvent:message];
        }
    }];
}

- (IBAction)pressRefresh:(id)sender {
    [self addStringEvent:@"Refreshing instances."];
    [self.arrayController setContent:nil];
    NSArray * masternodesArray = [[DPDataStore sharedInstance] allMasternodes];
    for (NSManagedObject * masternode in masternodesArray) {
        [self showTableContent:masternode];
        [[DPMasternodeController sharedInstance] checkMasternode:masternode];
    }
}

-(void)addStringEvent:(NSString*)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        if([string length] == 0 || string == nil) return;
        ConsoleEvent * consoleEvent = [ConsoleEvent consoleEventWithString:string];
        [self.consoleEvents addConsoleEvent:consoleEvent];
        [self updateConsole];
    });
}

-(void)updateConsole {
    NSString * consoleEventString = [self.consoleEvents printOut];
    self.consoleTextField.string = consoleEventString;
}

- (IBAction)selectDataTypes:(id)sender {
    
    
    
    NSLog(@"%@", [self.dataTypeItemsButton.selectedItem title]);
    
    if([[self.dataTypeItemsButton.selectedItem title] isEqualToString:@"All"]) {
        if([self.debugLogField.string length] != 0) {
            self.debugLogField.string = self.currentDebugLog;
            return;
        }
    }
    
    [self addStringEvent:[NSString stringWithFormat:@"Changing filter to %@", [self.dataTypeItemsButton.selectedItem title]]];
    self.debugLogField.string = @"";
    NSMutableString *cloneLogField = [NSMutableString string];
    
    [[DPNetworkController sharedInstance] findSpecificDataType:self.currentDebugLog datatype:[self.dataTypeItemsButton.selectedItem title] onClb:^(BOOL success, NSString *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [cloneLogField appendFormat:@"%@\n", message];
            self.debugLogField.string = cloneLogField;
        });
    }];
}


-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

@end
