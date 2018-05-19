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

@interface UnspentOutputViewController ()


@property (strong) IBOutlet NSTableView *unspentTable;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTextField *countField;
@property (strong) IBOutlet NSTextField *windowLog;
@property (strong) IBOutlet NSButton *selectAllButton;
@property (strong) IBOutlet NSTextField *labelField;

@end

@implementation UnspentOutputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    [[DPUnspentController sharedInstance] retreiveUnspentOutput:^(BOOL success,NSDictionary *dict, NSString *message){
        if(success)
        {
            self.windowLog.stringValue = @"Dash server started";
            NSMutableArray * unspentArray = [[DPUnspentController sharedInstance] processOutput:dict];
            [self processUnspentOutput:unspentArray];
        }
        else{
            self.windowLog.stringValue = @"Dash server didn't start up";
        }
    }];
}

-(AppDelegate*)appDelegate {
    return [NSApplication sharedApplication].delegate;
}

-(void)processUnspentOutput:(NSMutableArray*)unspentArray {
    
    [self.arrayController setContent:nil];
    for (NSDictionary* unspent in unspentArray) {
        [self showTableContent:unspent];
    }
}

-(void)showTableContent:(NSDictionary*)dictionary
{
    [self.arrayController addObject:dictionary];
    
    [self.arrayController rearrangeObjects];
    
    NSArray *array = [_arrayController arrangedObjects];
    NSUInteger row = [array indexOfObjectIdenticalTo:dictionary];
    
    [_unspentTable editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)pressRefresh:(id)sender {
    
    [[DPUnspentController sharedInstance] retreiveUnspentOutput:^(BOOL success,NSDictionary *dict, NSString *message){
        if(success)
        {
            self.windowLog.stringValue = @"Dash server started";
            NSMutableArray * unspentArray = [[DPUnspentController sharedInstance] processOutput:dict];
            [self processUnspentOutput:unspentArray];
        }
        else{
            self.windowLog.stringValue = @"Dash server didn't start up";
        }
    }];
}

- (IBAction)pressCreate:(id)sender {
    
    if([_countField integerValue] < 1){
        [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Please input amount of 1000 dash output."];
        return;
    }
    
    NSString *msgAlert = [NSString stringWithFormat:@"Are you sure you want to create %@ of 1000 dash unspent output", self.countField.stringValue];
    
    NSAlert *alert = [[DialogAlert sharedInstance] showAlertWithYesNoButton:@"Warning!" message:msgAlert];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [[DPUnspentController sharedInstance] createTransaction:self.countField.integerValue label:self.labelField.stringValue amount:1000 allObjects:[self.arrayController.arrangedObjects allObjects]];
        
        //refresh unspentlist
        [[DPUnspentController sharedInstance] retreiveUnspentOutput:^(BOOL success,NSDictionary *dict, NSString *message){
            if(success)
            {
                self.windowLog.stringValue = @"Dash server started";
                NSMutableArray * unspentArray = [[DPUnspentController sharedInstance] processOutput:dict];
                [self processUnspentOutput:unspentArray];
            }
            else{
                self.windowLog.stringValue = @"Dash server didn't start up";
            }
        }];
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

@end
