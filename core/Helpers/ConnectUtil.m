//
//  ConnectUtil.m
//  Connect SDK
//
//  Created by Jeremy White on 3/6/14.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ConnectUtil.h"


@implementation ConnectUtil

+ (NSString *)urlEncode:(NSString *)targetString
{
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *) [targetString UTF8String];
    int sourceLen = (int) strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];

        // credit: http://www.w3schools.com/tags/ref_urlencode.asp
        switch (thisChar)
        {
            case ' ': [output appendString:@"%20"]; break;
            case '!': [output appendString:@"%21"]; break;
            case '"': [output appendString:@"%22"]; break;
            case '#': [output appendString:@"%23"]; break;
            case '$': [output appendString:@"%24"]; break;
            case '%': [output appendString:@"%25"]; break;
            case '&': [output appendString:@"%26"]; break;
            case '\'': [output appendString:@"%27"]; break;
            case '(': [output appendString:@"%28"]; break;
            case ')': [output appendString:@"%29"]; break;
            case '*': [output appendString:@"%2A"]; break;
            case '+': [output appendString:@"%2B"]; break;
            case ',': [output appendString:@"%2C"]; break;
            case '-': [output appendString:@"%2D"]; break;
            case '.': [output appendString:@"%2E"]; break;
            case '/': [output appendString:@"%2F"]; break;
            case ':': [output appendString:@"%3A"]; break;
            case ';': [output appendString:@"%3B"]; break;
            case '<': [output appendString:@"%3C"]; break;
            case '=': [output appendString:@"%3D"]; break;
            case '>': [output appendString:@"%3E"]; break;
            case '?': [output appendString:@"%3F"]; break;
            case '@': [output appendString:@"%40"]; break;

            default:
                if ((thisChar >= 'a' && thisChar <= 'z') || (thisChar >= 'A' && thisChar <= 'Z') || (thisChar >= '0' && thisChar <= '9'))
                    [output appendFormat:@"%c", thisChar];
                else
                    [output appendFormat:@"%%%02X", thisChar];
        }
    }

    return output;
}

+ (NSString *)urlDecode:(NSString *)targetString
{
    NSString *result = [targetString stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

// credit: karsten @ stackoverflow.com (http://stackoverflow.com/users/272152/karsten)
// source: http://stackoverflow.com/a/2591544/2715
+ (NSString *) escapedUnicodeForString:(NSString *)input
{
    NSMutableString *uniString = [ [ NSMutableString alloc ] init ];
    UniChar *uniBuffer = (UniChar *) malloc ( sizeof(UniChar) * [ input length ] );
    CFRange stringRange = CFRangeMake ( 0, [ input length ] );

    CFStringGetCharacters ( (__bridge CFStringRef)input, stringRange, uniBuffer );

    for ( int i = 0; i < [ input length ]; i++ ) {
        if ( uniBuffer[i] < 0x30 || uniBuffer[i] > 0x7e )
            [ uniString appendFormat: @"\\u%04x", uniBuffer[i] ];
        else
            [ uniString appendFormat: @"%c", uniBuffer[i] ];
    }

    free ( uniBuffer );

    NSString *retString = [ NSString stringWithString: uniString ];

    return retString;
}

// TODO: remove this method as it's harmful and we should be using proper XML
// reader&writer instead
+ (NSString *) entityEncode:(NSString *)input
{
    NSString *output = [[[[input stringByReplacingOccurrencesOfString: @"&" withString: @"&amp;"]
            stringByReplacingOccurrencesOfString: @"\"" withString: @"&quot;"]
            stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]
            stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"];

    return output;
}

+ (NSString *) entityDecode:(NSString *)input
{
    NSString *output = [[[[input stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"]
            stringByReplacingOccurrencesOfString: @"&quot;" withString: @"\""]
            stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"]
            stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];

    return output;
}

@end
