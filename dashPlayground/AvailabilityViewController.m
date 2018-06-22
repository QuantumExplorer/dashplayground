//
//  AvailabilityViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 15/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import "AvailabilityViewController.h"
#import "DPAvailabilityController.h"
#import "DPMasternodeController.h"
#import "DialogAlert.h"

@interface AvailabilityViewController ()

@property (strong) IBOutlet NSComboBoxCell *regionComboButton;
@property (strong) IBOutlet NSButton *randomButton;

@end

@implementation AvailabilityViewController

AvailabilityViewController* _availWindowController;
NSInteger startCountField;
NSManagedObject * branchObject;
NSMutableArray * availabilityRegions;

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSLog(@"availability regions window loaded");
}

-(void)awakeFromNib {
    [self getAvailabilityRegions];
}

-(void)showAvailWindow:(NSInteger)count onBranch:(NSManagedObject*)branch clb:(dashInfoClb)clb {
    
    if([_availWindowController.window isVisible]) return;
    
    _availWindowController = [[AvailabilityViewController alloc] initWithWindowNibName:@"AvailabilityZoneWindow"];
    [_availWindowController.window makeKeyAndOrderFront:self];
    startCountField = count;
    branchObject = branch;
}

-(void)getAvailabilityRegions
{
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-regions" checkError:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            availabilityRegions = [NSMutableArray array];//initiate the object first
            for (NSDictionary * dictionary in output[@"Regions"]) {
                NSString *region = [dictionary valueForKey:@"RegionName"];
                [availabilityRegions addObject:region];
            }
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setDataButton:availabilityRegions];
        });
    });
    
}

-(void)setDataButton:(NSMutableArray*)availRegions
{
    [_regionComboButton removeAllItems];
    [_regionComboButton addItemsWithObjectValues:availRegions];
}

- (IBAction)confirmButton:(id)sender {
    NSMutableArray * selectRegionArray = [NSMutableArray array];
    if(_randomButton.state == 1)
    {
        for (int i = 1; i <= startCountField; i++)
        {
            NSUInteger randomIndex = arc4random() % [availabilityRegions count];
            [selectRegionArray addObject:[availabilityRegions objectAtIndex:randomIndex]];
        }
    }
    else {
        NSInteger selectRegion = [_regionComboButton indexOfSelectedItem];
        if(selectRegion == -1) {
            [[DialogAlert sharedInstance] showWarningAlert:@"Error" message:@"Please make sure you select availability zone."];
            return;
        }
        [selectRegionArray addObject:[availabilityRegions objectAtIndex:selectRegion]];
    }
    
    [[DPMasternodeController sharedInstance] setUpInstances:startCountField onBranch:branchObject clb:nil onRegion:selectRegionArray serverType:@"t2.micro"];
    [_availWindowController.window close];
}

@end
