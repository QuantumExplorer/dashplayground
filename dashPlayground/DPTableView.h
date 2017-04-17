//
//  DPTableView.h
//  dashPlayground
//
//  Created by Sam Westrich on 4/17/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol DPTableViewDelegate;

@interface DPTableView : NSTableView


@end

@protocol DPTableViewDelegate <NSTableViewDelegate>

-(BOOL)deleteKeyPressedForTableView:(DPTableView *)tableView;

@end
