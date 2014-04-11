//
// Created by Jeremy White on 3/6/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ConnectUtil : NSObject

+ (NSString *) urlEncode:(NSString *)input;
+ (NSString *) escapedUnicodeForString:(NSString *)input;

@end
