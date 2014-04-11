//
//  ConnectError.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 10/4/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ConnectStatusCodeError = 1000,
    ConnectStatusCodeTvError = 1001,
    ConnectStatusCodeCertificateError = 1002,
    ConnectStatusCodeSocketError = 1003,

    ConnectStatusCodeNotSupported = 1100,
    ConnectStatusCodeArgumentError = 1101
} ConnectStatusCode;

@interface ConnectError : NSObject

+ (NSError *) generateErrorWithCode:(ConnectStatusCode)code andDetails:(id)details;

@end
