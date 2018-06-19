//
//  UnspentOutputViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 10/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "UnspentOutputViewController.h"
#import "DPUnspentController.h"
#import "DialogAlert.h"
#import "DPDataStore.h"

@interface UnspentOutputViewController ()


@property (strong) IBOutlet NSTableView *unspentTable;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTextField *countField;
@property (strong) IBOutlet NSTextField *windowLog;
@property (strong) IBOutlet NSButton *selectAllButton;
@property (strong) IBOutlet NSTextField *labelField;
@property (strong) IBOutlet NSButton *refreshButton;

@end

@implementation UnspentOutputViewController

-(id)init
{
    [self.unspentTable setDelegate: (id)self];
    [self.unspentTable setDataSource: (id)self];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    [self.unspentTable setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
    
    [[DPUnspentController sharedInstance] retreiveUnspentOutput:^(BOOL success,NSDictionary *dict, NSString *message){
        if(success)
        {
            self.windowLog.stringValue = @"Dash server started";
            [self.arrayController setContent:nil];
            [self processOutput:dict forChain:chainNetwork];
        }
        else{
            self.windowLog.stringValue = @"Dash server didn't start up";
        }
    } forChain:chainNetwork];
}

-(void)processOutput:(NSDictionary*)unspentOutputs forChain:(NSString*)chainNetwork {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        for (NSDictionary* unspent in unspentOutputs) {
            
            [self showTableContent:unspent];
        }
        
    });
    
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

-(void)processUnspentOutput:(NSMutableArray*)unspentArray {
    
//    if([unspentArray count] == 0) {
//        [self.arrayController setContent:nil];
//        return;
//    }
    for (NSDictionary* unspent in unspentArray) {
        [self showTableContent:unspent];
    }
}

-(void)showTableContent:(NSDictionary*)dictionary
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.arrayController addObject:dictionary];
        
        [self.arrayController rearrangeObjects];

//        NSArray *array = [self.arrayController arrangedObjects];
//        NSUInteger row = [array indexOfObjectIdenticalTo:dictionary];
        
//        [self.unspentTable editColumn:0 row:row withEvent:nil select:YES];
    });

}

- (IBAction)pressRefresh:(id)sender {
    
    NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
    
    self.refreshButton.state = true;
    [[DPUnspentController sharedInstance] retreiveUnspentOutput:^(BOOL success,NSDictionary *dict, NSString *message){
        if(success)
        {
            self.windowLog.stringValue = @"Dash server started";
            [self.arrayController setContent:nil];
            [self processOutput:dict forChain:chainNetwork];
        }
        else{
            self.windowLog.stringValue = @"Dash server didn't start up";
        }
    } forChain:chainNetwork];
}

- (IBAction)pressCreate:(id)sender {
    
    if([_countField integerValue] < 1){
        [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Please input amount of 1000 dash output."];
        return;
    }
    
    NSString *msgAlert = [NSString stringWithFormat:@"Are you sure you want to create %@ unspent outputs with 1000 dash?", self.countField.stringValue];
    
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Warning!" message:msgAlert];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        
        NSString *chainNetwork = [[DPDataStore sharedInstance] chainNetwork];
        
        NSArray *cloneObjects = [NSArray array];
        cloneObjects = [self.arrayController.arrangedObjects allObjects];
        
        [[DPUnspentController sharedInstance] createTransaction:self.countField.integerValue label:self.labelField.stringValue amount:1000 allObjects:cloneObjects clb:^(BOOL success, NSMutableArray *newObjects) {
            
            if(newObjects != nil) [self processUnspentOutput:newObjects];
        } forChain:chainNetwork];
        
//        [self deSelectAll];
        [self clearInputFields];
    }
    
}

- (IBAction)pressClear:(id)sender {
    [self clearInputFields];
}

-(void)clearInputFields {
    self.labelField.stringValue = @"";
    self.countField.stringValue = @"";
}

- (IBAction)pressSelectAll:(id)sender {
    
    NSString *stateValue;
    if(self.selectAllButton.state == 1){
        stateValue = @"1";
    }
    else{
        stateValue = @"0";
    }
    
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        [object setValue:stateValue forKey:@"selected"];
    }
    
}

-(void)deSelectAll {
    self.selectAllButton.state = 0;
    for(NSManagedObject *object in [self.arrayController.arrangedObjects allObjects])
    {
        [object setValue:@"0" forKey:@"selected"];
    }
}



@end
