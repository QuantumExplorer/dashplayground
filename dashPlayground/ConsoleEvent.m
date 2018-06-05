//
//  ConsoleEvent.m
//  dashPlayground
//
//  Created by Sam Westrich on 7/4/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "ConsoleEvent.h"

@interface ConsoleEvent()

@property(nonatomic,strong) NSString * identifier;
@property(nonatomic,strong) NSString* string;
@property(nonatomic,strong) NSArray* componentNames;
@property(nonatomic,strong) NSDate* creationDate;
@property(nonatomic,strong) NSMutableDictionary* values;

@end

@implementation ConsoleEvent

+(ConsoleEvent*)consoleEventWithString:(NSString*)string {
    ConsoleEvent * consoleEvent = [ConsoleEvent new];
    consoleEvent.identifier = [[NSUUID UUID] UUIDString];
    consoleEvent.string = string;
    consoleEvent.creationDate = [NSDate date];
    consoleEvent.componentNames = [NSArray array];
    consoleEvent.values = [NSMutableDictionary dictionary];
    return consoleEvent;
}

+(ConsoleEvent*)consoleEventWithFormattedString:(NSString*)string componentNames:(NSArray*)componentNames defaultValues:(NSArray*)defaultValues {
    NSAssert([componentNames count] == [defaultValues count],@"component count and default values count must be the same");
    ConsoleEvent * consoleEvent = [ConsoleEvent new];
    consoleEvent.identifier = [[NSUUID UUID] UUIDString];
    consoleEvent.string = string;
    consoleEvent.creationDate = [NSDate date];
    consoleEvent.componentNames = componentNames;
    consoleEvent.values = [NSMutableDictionary dictionaryWithObjects:defaultValues forKeys:componentNames];
    return consoleEvent;
}

-(NSString*)printOut {
    if ([self.componentNames count]) {
        NSArray * keys = [self.values objectsForKeys:self.componentNames notFoundMarker:[NSNull null]];
        NSRange range = NSMakeRange(0, [keys count]);
        NSMutableData *data = [NSMutableData dataWithLength:sizeof(id) * [keys count]];
        [keys getObjects:(__unsafe_unretained id *)data.mutableBytes range:range];
        return [NSString stringWithFormat:@"[%@]: %@",[self.dateFormatter stringFromDate:self.creationDate],[[NSString alloc] initWithFormat:self.string arguments:data.mutableBytes]];
    } else {
        return [NSString stringWithFormat:@"[%@]: %@",[self.dateFormatter stringFromDate:self.creationDate],self.string];
    }
}

@end
