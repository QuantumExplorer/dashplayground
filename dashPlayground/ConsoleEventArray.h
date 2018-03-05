//
//  ConsoleEventArray.h
//  dashPlayground
//
//  Created by Sam Westrich on 7/4/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConsoleEvent.h"

@interface ConsoleEventArray : NSObject

-(void)addConsoleEvent:(ConsoleEvent*)consoleEvent;

-(NSString*)printOut;

@end
