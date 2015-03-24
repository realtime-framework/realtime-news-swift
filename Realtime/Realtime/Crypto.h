//
//  Crypto.h
//  Realtime
//
//  Created by Joao Caixinha on 11/03/15.
//  Copyright (c) 2015 Realtime. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

@interface Crypto : NSObject
@property(retain, nonatomic)NSString *desc;

- (id)initWithString:(NSString*)md5;
+ (NSString*)MD5FromString:(NSString*)string;

@end
