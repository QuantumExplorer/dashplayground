//
//  Defines.h
//  dashPlayground
//
//  Created by Sam Westrich on 3/25/17.
//  Copyright © 2017 dashfoundation. All rights reserved.
//

#ifndef Defines_h
#define Defines_h

#define GREATER_THAN(w,v)              ([w compare:v options:NSNumericSearch] == NSOrderedDescending)
#define GREATER_THAN_OR_EQUAL_TO(w,v)  ([w compare:v options:NSNumericSearch] != NSOrderedAscending)
#define LESS_THAN(w,v)                 ([w compare:v options:NSNumericSearch] == NSOrderedAscending)
#define LESS_THAN_OR_EQUAL_TO(w,v)     ([w compare:v options:NSNumericSearch] != NSOrderedDescending)
#define BETWEEN_INCLUDE(w,v,z)     (GREATER_THAN_OR_EQUAL_TO(w,v) && LESS_THAN_OR_EQUAL_TO(w,z))
#define BETWEEN_EXCLUDE(w,v,z)     (GREATER_THAN(w,v) && LESS_THAN(w,z))
#define BETWEEN_INEX(w,v,z)     (GREATER_THAN_OR_EQUAL_TO(w,v) && LESS_THAN(w,z))
#define BETWEEN_EXIN(w,v,z)     (GREATER_THAN(w,v) && LESS_THAN_OR_EQUAL_TO(w,z))

#define FS(str, args...) [NSString stringWithFormat:str, ## args]

#define DS(data) [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]

#define SD(string) [string dataUsingEncoding:NSUTF8StringEncoding]

#endif /* Defines_h */
