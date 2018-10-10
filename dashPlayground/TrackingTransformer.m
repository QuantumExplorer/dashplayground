//
//  TrackingTransformer.m
//  dashPlayground
//
//  Created by Sam Westrich on 4/11/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#import "TrackingTransformer.h"

@implementation TrackingTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
//    if (value) {
//        NSDataDetector *linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
//        NSArray *matches = [linkDetector matchesInString:value options:0 range:NSMakeRange(0, [value length])];
//        if ([matches count] && [matches[0] isKindOfClass:[NSTextCheckingResult class]] && ((NSTextCheckingResult*)matches[0]).resultType == NSTextCheckingTypeLink) {
//            NSURL * url = ((NSTextCheckingResult*)matches[0]).URL;
//            if ([url.host isEqualToString:@"github.com"] && url.pathComponents.count > 2) {
//                return [NSString stringWithFormat:@"gh:%@/%@",url.pathComponents[1],[url.pathComponents[2] stringByDeletingPathExtension]];
//            }
//        }
//
//    }
    return value;
}


@end
