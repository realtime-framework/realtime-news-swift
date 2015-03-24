//
//  Crypto.m
//  Realtime
//
//  Created by Joao Caixinha on 11/03/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

#import "Crypto.h"

@implementation Crypto

- (id)initWithString:(NSString*)plainText
{
    self = [super init];
    if (self) {
        _desc = [[self class] MD5FromString:plainText];
    }
    return self;
}

- (NSString*)description
{
    return _desc;
}

+ (NSString*)MD5FromString:(NSString*)string
{
    // Create pointer to the string as UTF8
    const char *ptr = [string UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 bytes MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end
