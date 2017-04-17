//
//  DPTableView.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/17/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "DPTableView.h"

@implementation DPTableView

+(unichar)firstCharPressedForEvent:(NSEvent *)theEvent {
    if (![[theEvent characters] length]) return -1;
    return [[theEvent characters] characterAtIndex:0];
}

+(BOOL)eventIsDeleteKeyPressed:(NSEvent *)theEvent {
    switch ([DPTableView firstCharPressedForEvent:theEvent]) {
        case NSDeleteFunctionKey:
        case NSDeleteCharFunctionKey:
        case NSDeleteCharacter:
            return YES;
        default:
            return NO;
    }
}

-(void)keyDown:(NSEvent *)theEvent {
    if ([DPTableView eventIsDeleteKeyPressed:theEvent])
        if ([[self delegate] respondsToSelector:@selector(deleteKeyPressedForTableView:)])
            if ([(id<DPTableViewDelegate>)[self delegate] deleteKeyPressedForTableView:self])
                return;
    
    // The delegate wasn't able to handle it
    [super keyDown:theEvent];
}
@end
