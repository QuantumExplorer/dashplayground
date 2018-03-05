//
//  ConsoleEventArray.m
//  dashPlayground
//
//  Created by Sam Westrich on 7/4/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "ConsoleEventArray.h"

@interface ConsoleEventArray()

@property (nonatomic,strong) NSMutableArray * consoleEventsArray;
@property (nonatomic,strong) NSDateFormatter * dateFormatter;

@end

@implementation ConsoleEventArray

-(id)init {
    if (self) {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"HH:mm:ss"];
        self.consoleEventsArray = [NSMutableArray array];
    }
    return self;
}

-(void)addConsoleEvent:(ConsoleEvent*)consoleEvent {
    [consoleEvent setDateFormatter:self.dateFormatter];
    [self.consoleEventsArray addObject:consoleEvent];
}

-(NSString*)printOut {
    NSMutableString * string = [[NSMutableString alloc] init];
    for (ConsoleEvent * consoleEvent in self.consoleEventsArray) {
        [string appendFormat:@"%@\n",consoleEvent.printOut];
    }
    return string;
}

@end
