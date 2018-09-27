//
//  NSData+Bitcoin.h
//  DashSync
//
//  Created by Aaron Voisine on 10/09/13.
//  Copyright (c) 2013 Aaron Voisine <voisine@gmail.com>
//  Updated by Quantum Explorer on 05/11/18.
//  Copyright (c) 2018 Quantum Explorer <quantum@dash.org>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>

#define SEC_ATTR_SERVICE    @"org.dashresearchasia.dashplayground"

//Keychain

BOOL setKeychainData(NSData *data, NSString *key, BOOL authenticated);
BOOL hasKeychainData(NSString *key, NSError **error);
NSData *getKeychainData(NSString *key, NSError **error);
BOOL setKeychainInt(int64_t i, NSString *key, BOOL authenticated);
int64_t getKeychainInt(NSString *key, NSError **error);
BOOL setKeychainString(NSString *s, NSString *key, BOOL authenticated);
NSString *getKeychainString(NSString *key, NSError **error);
BOOL setKeychainDict(NSDictionary *dict, NSString *key, BOOL authenticated);
NSDictionary *getKeychainDict(NSString *key, NSError **error);
BOOL setKeychainArray(NSArray *array, NSString *key, BOOL authenticated);
NSArray *getKeychainArray(NSString *key, NSError **error);


@interface NSData (Security)

@end

