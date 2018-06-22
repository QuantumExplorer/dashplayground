//
//  AWSViewController.m
//  dashPlayground
//
//  Created by NATTAPON AIEMLAOR on 21/6/18.
//  Copyright © 2018 dashfoundation. All rights reserved.
//

#import "AWSViewController.h"
#import "DPMasternodeController.h"
#import "PreferenceData.h"
#import "DialogAlert.h"

@interface AWSViewController ()
@property (strong) IBOutlet NSArrayController *subnetArrayController;
@property (strong) IBOutlet NSArrayController *securityGrArrayController;
@property (strong) IBOutlet NSArrayController *keyPairArrayController;
@property (strong) IBOutlet NSTableView *securityTable;
@property (strong) IBOutlet NSTableView *subnetTable;
@property (strong) IBOutlet NSTableView *keyPairTable;
@property (strong) IBOutlet NSTextField *awsPathField;
@property (strong) IBOutlet NSTextField *keyPairField;

@end

@implementation AWSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
//    NSLog(@"%@, %@, %@", [[PreferenceData sharedInstance] getAWSPath], [[PreferenceData sharedInstance] getSecurityGroupId], [[PreferenceData sharedInstance] getKeyName]);
    [self initialize];
}

- (void)initialize {
    if([[PreferenceData sharedInstance] getAWSPath] != nil) self.awsPathField.stringValue = [[PreferenceData sharedInstance] getAWSPath];
    if([[DPMasternodeController sharedInstance] sshPath] != nil) self.keyPairField.stringValue = [[DPMasternodeController sharedInstance] sshPath];
    [self fetchingSecurityGr];
    [self fetchingSubnet];
    [self fetchingKeyPairs];
}

- (IBAction)browseAWSPath:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:YES];
    [openDlg setAllowsMultipleSelection:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        NSString* filePath = [openDlg URL].absoluteString;
        if([filePath length] >= 7) {
            filePath = [filePath substringFromIndex:7];
            self.awsPathField.stringValue = filePath;
        }
    }
}

- (IBAction)browseKeyPair:(id)sender {
    
    NSArray *fileInfo = [[DialogAlert sharedInstance] getSSHLaunchPathAndName];
    self.keyPairField.stringValue = fileInfo[1];
}

- (void) addRowToArrayController:(NSArrayController *)arrayCon tableView:(NSTableView *)tableView dict:(NSDictionary *)dict {
    
    [arrayCon addObject:dict];
    
    [arrayCon rearrangeObjects];
    
    NSArray *array = [arrayCon arrangedObjects];
    NSUInteger row = [array indexOfObjectIdenticalTo:dict];
    
    [tableView editColumn:0 row:row withEvent:nil select:YES];
    
}

- (void) fetchingSecurityGr {
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-security-groups" checkError:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            if(output[@"SecurityGroups"])
            {
                [self.securityGrArrayController setContent:nil];//clear the table content
            }
            for (NSDictionary * dictionary in output[@"SecurityGroups"]) {
                
                NSDictionary *dict = @{@"groupID":[dictionary valueForKey:@"GroupId"]
                                       ,@"groupName":[dictionary valueForKey:@"GroupName"]
                                       ,@"vpcID":[dictionary valueForKey:@"VpcId"]
                                       };
                
                [self addRowToArrayController:self.securityGrArrayController tableView:self.securityTable dict:dict];
            }
        });
    });
}

- (void) fetchingSubnet {
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-subnets"  checkError:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            if(output[@"Subnets"])
            {
                [self.subnetArrayController setContent:nil];//clear the table content
            }
            for (NSDictionary * dictionary in output[@"Subnets"]) {
                NSDictionary *dict = @{@"subnetID":[dictionary valueForKey:@"SubnetId"]
                                       ,@"availZone":[dictionary valueForKey:@"AvailabilityZone"]
                                       ,@"state":[dictionary valueForKey:@"State"]
                                       };
                [self addRowToArrayController:self.subnetArrayController tableView:self.subnetTable dict:dict];
            }
        });
    });
}

- (void) fetchingKeyPairs {
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-key-pairs"  checkError:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            if(output[@"KeyPairs"])
            {
                [self.keyPairArrayController setContent:nil];//clear the table content
            }
            for (NSDictionary * dictionary in output[@"KeyPairs"]) {
                NSDictionary *dict = @{@"keyName":[dictionary valueForKey:@"KeyName"]
                                       ,@"fingerprint":[dictionary valueForKey:@"KeyFingerprint"]
                                       };
                [self addRowToArrayController:self.keyPairArrayController tableView:self.keyPairTable dict:dict];
            }
        });
    });
}

- (IBAction)refreshSecurityGr:(id)sender {
    [self fetchingSecurityGr];
}

- (IBAction)refreshSubnet:(id)sender {
    [self fetchingSubnet];
}

- (IBAction)refreshKeyPair:(id)sender {
    [self fetchingKeyPairs];
}

- (IBAction)pressSave:(id)sender {
    NSInteger securityRow = self.securityTable.selectedRow;
    NSInteger subnetRow = self.subnetTable.selectedRow;
    NSInteger keyPairRow = self.keyPairTable.selectedRow;
    
    if(securityRow != -1)
    {
        NSManagedObject * object = [self.securityGrArrayController.arrangedObjects objectAtIndex:securityRow];
        [[PreferenceData sharedInstance] setSecurityGroupId:[object valueForKey:@"groupID"]];
    }
    
    if(subnetRow != -1)
    {
        NSManagedObject * object = [self.subnetArrayController.arrangedObjects objectAtIndex:subnetRow];
        [[PreferenceData sharedInstance] setSubnetID:[object valueForKey:@"subnetID"]];
    }
    
    if(keyPairRow != -1)
    {
        NSManagedObject * object = [self.keyPairArrayController.arrangedObjects objectAtIndex:keyPairRow];
        [[PreferenceData sharedInstance] setKeyName:[object valueForKey:@"keyName"]];
    }
    
    if([self.awsPathField.stringValue length] != 0) [[PreferenceData sharedInstance] setAWSPath:self.awsPathField.stringValue];
    
    if([self.keyPairField.stringValue length] != 0) [[DPMasternodeController sharedInstance] setSshPath:self.keyPairField.stringValue];
    
    [self dismissController:sender];
}

@end
