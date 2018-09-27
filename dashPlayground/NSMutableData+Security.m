//
//  NSMutableData+Dash.m
//  DashSync
//
//  Created by Aaron Voisine on 5/20/13.
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

#import "NSMutableData+Security.h"
#import "NSData+Security.h"

static void *secureAllocate(CFIndex allocSize, CFOptionFlags hint, void *info)
{
    void *ptr = malloc(sizeof(CFIndex) + allocSize);
    
    if (ptr) { // we need to keep track of the size of the allocation so it can be cleansed before deallocation
        *(CFIndex *)ptr = allocSize;
        return (CFIndex *)ptr + 1;
    }
    else return NULL;
}

static void secureDeallocate(void *ptr, void *info)
{
    CFIndex size = *((CFIndex *)ptr - 1);
    
    if (size) {
        memset(ptr, 0, size);
        free((CFIndex *)ptr - 1);
    }
}

static void *secureReallocate(void *ptr, CFIndex newsize, CFOptionFlags hint, void *info)
{
    // There's no way to tell ahead of time if the original memory will be deallocted even if the new size is smaller
    // than the old size, so just cleanse and deallocate every time.
    void *newptr = secureAllocate(newsize, hint, info);
    CFIndex size = *((CFIndex *)ptr - 1);
    
    if (newptr && size) {
        memcpy(newptr, ptr, (size < newsize) ? size : newsize);
        secureDeallocate(ptr, info);
    }
    
    return newptr;
}

// Since iOS does not page memory to storage, all we need to do is cleanse allocated memory prior to deallocation.
CFAllocatorRef SecureAllocator()
{
    static CFAllocatorRef alloc = NULL;
    static dispatch_once_t onceToken = 0;
    
    dispatch_once(&onceToken, ^{
        CFAllocatorContext context;
        
        context.version = 0;
        CFAllocatorGetContext(kCFAllocatorDefault, &context);
        context.allocate = secureAllocate;
        context.reallocate = secureReallocate;
        context.deallocate = secureDeallocate;
        
        alloc = CFAllocatorCreate(kCFAllocatorDefault, &context);
    });
    
    return alloc;
}

@implementation NSMutableData (Security)

+ (NSMutableData *)secureData
{
    return [self secureDataWithCapacity:0];
}

+ (NSMutableData *)secureDataWithCapacity:(NSUInteger)aNumItems
{
    return CFBridgingRelease(CFDataCreateMutable(SecureAllocator(), aNumItems));
}

+ (NSMutableData *)secureDataWithLength:(NSUInteger)length
{
    NSMutableData *d = [self secureDataWithCapacity:length];

    d.length = length;
    return d;
}

+ (NSMutableData *)secureDataWithData:(NSData *)data
{
    return CFBridgingRelease(CFDataCreateMutableCopy(SecureAllocator(), 0, (CFDataRef)data));
}

- (void)appendUInt8:(uint8_t)i
{
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt16:(uint16_t)i
{
    i = CFSwapInt16HostToLittle(i);
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt32:(uint32_t)i
{
    i = CFSwapInt32HostToLittle(i);
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt64:(uint64_t)i
{
    i = CFSwapInt64HostToLittle(i);
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt128:(UInt128)i
{
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt160:(UInt160)i
{
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendUInt256:(UInt256)i
{
    [self appendBytes:&i length:sizeof(i)];
}

- (void)appendString:(NSString *)s
{
    NSUInteger l = [s lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

    [self appendVarInt:l];
    [self appendBytes:s.UTF8String length:l];
}

@end
