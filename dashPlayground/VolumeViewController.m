//
//  VolumeViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 2/5/2561 BE.
//  Copyright © 2561 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VolumeViewController.h"
#import "DPMasternodeController.h"
#import "DialogAlert.h"

@interface VolumeViewController ()

@property (strong) IBOutlet NSTableView *volumeTable;
@property (strong) IBOutlet NSArrayController *volumeArrayCon;
@property (strong) IBOutlet NSTextField *instanceIdField;
@property (strong) IBOutlet NSTextField *imageNameField;
@property (strong) IBOutlet NSTextField *imageDescField;
@property (strong) IBOutlet NSButton *noRebootButton;

@end

@implementation VolumeViewController

VolumeViewController* _volumeController;
NSString *instanceId;

- (void)awakeFromNib {
    
    NSLog(@"volume window loaded");
    
    
    [self getAMI:instanceId];
}

-(void)showAMIWindow:(NSString*)instanceID {
    
    instanceId = instanceID;
    
    _volumeController = [[VolumeViewController alloc] initWithWindowNibName:@"VolumeWindow"];
    [_volumeController.window makeKeyAndOrderFront:self];
}

-(void)getAMI:(NSString*)instanceID
{
    _instanceIdField.stringValue = instanceID;
    
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    NSMutableArray * volume = [NSMutableArray array];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:[NSString stringWithFormat:@"ec2 describe-volumes --filters Name=attachment.instance-id,Values=%@", instanceID]];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            for (NSDictionary * dictionary in output[@"Volumes"]) {

                NSDictionary * rDict = [NSMutableDictionary dictionary];

                [rDict setValue:[dictionary valueForKey:@"Encrypted"] forKey:@"encrypted"];
                [rDict setValue:[dictionary valueForKey:@"Size"] forKey:@"size"];
                [rDict setValue:[dictionary valueForKey:@"SnapshotId"] forKey:@"snapshotId"];
                [rDict setValue:[dictionary valueForKey:@"Iops"] forKey:@"iops"];
                [rDict setValue:[dictionary valueForKey:@"VolumeType"] forKey:@"volumeType"];


                for (NSDictionary * dictionaries in dictionary[@"Attachments"]) {
                    [rDict setValue:[dictionaries valueForKey:@"Device"] forKey:@"device"];
                    [rDict setValue:[dictionaries valueForKey:@"DeleteOnTermination"] forKey:@"deleteOnTermination"];

                }
                [volume addObject:rDict];
            }
        });

        dispatch_async(dispatch_get_main_queue(), ^{
            [_volumeArrayCon setContent:nil];
            for (NSDictionary* reference in volume) {
                [self showContentToTable:reference];
            }
        });

    });
}

-(void)showContentToTable:(NSDictionary*)dictionary
{
    [_volumeArrayCon addObject:dictionary];

    [_volumeArrayCon rearrangeObjects];

    NSArray *array = [_volumeArrayCon arrangedObjects];
    NSUInteger row = [array indexOfObjectIdenticalTo:dictionary];

    [_volumeTable editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)pressCreateImage:(id)sender {
    
    NSString *imageName = [self.imageNameField stringValue];
    NSString *imageDesc = [self.imageDescField stringValue];
    BOOL isReboot = false;
    NSManagedObject * object = [self.volumeArrayCon.arrangedObjects objectAtIndex:0];
    NSMutableString *deleteOnTerminationValue = [[NSMutableString alloc]init];
    
    if (!imageName || [imageName isEqualToString:@""]
        || !imageDesc || [imageDesc isEqualToString:@""]
        )
    {
        [[DialogAlert sharedInstance] showAlertWithOkButton:@"Unable to create new image!" message:@"Please make sure you already fill every text fields."];
    }
    else{
        
        DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
        
        if(self.noRebootButton.state == 1){isReboot = true;}
        
        if([[[object valueForKey:@"deleteOnTermination"] stringValue] isEqualToString:@"1"])
        {
            [deleteOnTerminationValue setString:@"true"];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            
            NSDictionary *output;
            
            if(isReboot){
                output = [DPmasternodeCon runAWSCommandJSON:[NSString stringWithFormat:@"ec2 create-image --instance-id %@ --name \"%@\" --description \"%@\" --block-device-mappings DeviceName=\"%@\",Ebs={DeleteOnTermination=%@VolumeType=\"%@\",VolumeSize=%@}", instanceId, imageName, imageDesc, [object valueForKey:@"device"], deleteOnTerminationValue, [object valueForKey:@"volumeType"], [object valueForKey:@"size"]]];
            }else{
                output = [DPmasternodeCon runAWSCommandJSON:[NSString stringWithFormat:@"ec2 create-image --instance-id %@ --name \"%@\" --description \"%@\" --no-reboot --block-device-mappings DeviceName=\"%@\",Ebs={DeleteOnTermination=%@,VolumeType=\"%@\",VolumeSize=%@}", instanceId, imageName, imageDesc, [object valueForKey:@"device"], deleteOnTerminationValue, [object valueForKey:@"volumeType"], [object valueForKey:@"size"]]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if(output[@"ImageId"])
                {
                    [[DialogAlert sharedInstance] showAlertWithOkButton:@"Create image!" message:@"The image is created succesfully."];
                    [_volumeController.window close];
                }
            });
        });
        
    }
}


@end
