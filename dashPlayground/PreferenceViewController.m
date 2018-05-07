//
//  PreferenceViewController
//  dashPlayground

#import "PreferenceViewController.h"
#import "AppDelegate.h"
#import "PreferenceData.h"
#import "DPDataStore.h"
#import "DPMasternodeController.h"
#import "DialogAlert.h"

@interface PreferenceViewController ()

//@property (nonatomic, strong) IBOutlet NSTableView *SecurityTable;
@property (strong) IBOutlet NSArrayController *securityArrayController;
@property (strong) IBOutlet NSTableView *securityTable;
@property (strong) IBOutlet NSTableView *subnetTable;
@property (strong) IBOutlet NSArrayController *subnetArrayController;
@property (strong) IBOutlet NSArrayController *keyPairArrayController;
@property (strong) IBOutlet NSTableView *keyPairTable;

@end

@implementation PreferenceViewController

PreferenceViewController* _windowController;

- (void)awakeFromNib {

    NSLog(@"configuring window loaded");

    [self fetchingSecurityGr];
    [self fetchingSubnet];
    [self fetchingKeyPairs];
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
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-security-groups"];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            if(output[@"SecurityGroups"])
            {
                [_securityArrayController setContent:nil];//clear the table content
            }
            for (NSDictionary * dictionary in output[@"SecurityGroups"]) {
                
                NSDictionary *dict = @{@"groupID":[dictionary valueForKey:@"GroupId"]
                                        ,@"groupName":[dictionary valueForKey:@"GroupName"]
                                        ,@"vpcID":[dictionary valueForKey:@"VpcId"]
                                        };
                
                [self addRowToArrayController:_securityArrayController tableView:_securityTable dict:dict];
            }
        });
    });
}

- (void) fetchingSubnet {
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-subnets"];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            if(output[@"Subnets"])
            {
                [_subnetArrayController setContent:nil];//clear the table content
            }
            for (NSDictionary * dictionary in output[@"Subnets"]) {
                NSDictionary *dict = @{@"subnetID":[dictionary valueForKey:@"SubnetId"]
                                        ,@"availZone":[dictionary valueForKey:@"AvailabilityZone"]
                                        ,@"state":[dictionary valueForKey:@"State"]
                                        };
                [self addRowToArrayController:_subnetArrayController tableView:_subnetTable dict:dict];
            }
        });
    });
}

- (void) fetchingKeyPairs {
    DPMasternodeController *DPmasternodeCon = [[DPMasternodeController alloc]init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        NSDictionary *output = [DPmasternodeCon runAWSCommandJSON:@"ec2 describe-key-pairs"];
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"%@",reservation[@"Instances"]);
            if(output[@"KeyPairs"])
            {
                [_keyPairArrayController setContent:nil];//clear the table content
            }
            for (NSDictionary * dictionary in output[@"KeyPairs"]) {
                NSDictionary *dict = @{@"keyName":[dictionary valueForKey:@"KeyName"]
                                        ,@"fingerprint":[dictionary valueForKey:@"KeyFingerprint"]
                                        };
                [self addRowToArrayController:_keyPairArrayController tableView:_keyPairTable dict:dict];
            }
        });
    });
}

- (IBAction)refreshSubnet:(id)sender {
    [self fetchingSubnet];
}


- (IBAction)createSubnet:(id)sender {
    
//    NSDictionary *dict = @{@"subnetID":@"231324"
//                           ,@"availZone":@"Toey2"
//                           ,@"state":@"4323236"
//                           };
//    [self.subnetArrayController addObject:dict];
//
//    [self.subnetArrayController rearrangeObjects];
//
//    NSArray *array = [self.subnetArrayController arrangedObjects];
//    NSUInteger row = [array indexOfObjectIdenticalTo:dict];
//
//    [self.subnetTable editColumn:0 row:row withEvent:nil select:YES];
}

- (IBAction)refreshSecurityGr:(id)sender {
    [self fetchingSecurityGr];
}

- (IBAction)createSecurityGroup:(id)sender {
    
//    NSDictionary *dict = @{@"groupID":@"123"
//                           ,@"groupName":@"Toey"
//                           ,@"vpcID":@"456"
//                           };
//    [self.securityArrayController addObject:dict];
//    
//    [self.securityArrayController rearrangeObjects];
//
//    NSArray *array = [self.securityArrayController arrangedObjects];
//    NSUInteger row = [array indexOfObjectIdenticalTo:dict];
//    
//    [self.securityTable editColumn:0 row:row withEvent:nil select:YES];
    
}

- (IBAction)refreshKeyPair:(id)sender {
    [self fetchingKeyPairs];
}

- (IBAction)createKeyPair:(id)sender {
    
    
}

-(void)showConfiguringWindow {
    
    _windowController = [[PreferenceViewController alloc] initWithWindowNibName:@"PreferenceWindow"];
//    [_windowController showWindow:self];
    [_windowController.window makeKeyAndOrderFront:self];
}

- (IBAction)pressSave:(id)sender {
    
    NSInteger securityRow = self.securityTable.selectedRow;
    NSInteger subnetRow = self.subnetTable.selectedRow;
    NSInteger keyPairRow = self.keyPairTable.selectedRow;
    
    if(securityRow != -1)
    {
        NSManagedObject * object = [self.securityArrayController.arrangedObjects objectAtIndex:securityRow];
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
    
    [[DialogAlert sharedInstance] showAlertWithOkButton:@"Data saved!" message:@"All of preference data are saved."];
    
    [_windowController.window close];
}

@end
