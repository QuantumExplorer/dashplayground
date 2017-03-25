//
//  ViewController.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/24/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LoginViewController : NSViewController

@property (nonatomic,strong) IBOutlet NSTextField * startCountField;

- (IBAction)pressStartIntances:(id)sender;

@end

