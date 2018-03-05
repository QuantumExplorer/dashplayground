//
//  ConsoleEvent.h
//  dashPlayground
//
//  Created by Sam Westrich on 7/4/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ConsoleEvent : NSObject

@property(readonly,nonatomic,strong) NSString * identifier;
@property (nonatomic,strong) NSDateFormatter * dateFormatter;


+(ConsoleEvent*)consoleEventWithString:(NSString*)string;
+(ConsoleEvent*)consoleEventWithFormattedString:(NSString*)string componentNames:(NSArray*)componentNames defaultValues:(NSArray*)defaultValues;

-(NSString*)printOut;

@end
