//
//  ViewController.m
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "LoginViewController.h"
#import "DPMasternodeController.h"

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}
- (IBAction)pressStartIntances:(id)sender {
    [[DPMasternodeController sharedInstance] runInstances:[self.startCountField integerValue]];
}



@end
