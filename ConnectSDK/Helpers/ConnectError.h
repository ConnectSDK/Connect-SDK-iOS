//
//  ConnectError.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 10/4/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 * Helpful status codes that augment the localizedDescriptions of NSErrors that crop up throughout many places of the SDK. Most NSErrors that Connect SDK provides will have a ConnectStatusCode.
 */
typedef enum {
    /*! Generic error, unknown cause */
    ConnectStatusCodeError = 1000,

    /*! The TV experienced an error */
    ConnectStatusCodeTvError = 1001,

    /*! SSL certificate error */
    ConnectStatusCodeCertificateError = 1002,

    /*! Error with WebSocket connection */
    ConnectStatusCodeSocketError = 1003,

    /*! Requested action is not supported */
    ConnectStatusCodeNotSupported = 1100,

    /*! There was a problem with the provided arguments, see error description for details */
    ConnectStatusCodeArgumentError = 1101
} ConnectStatusCode;

@interface ConnectError : NSObject

+ (NSError *) generateErrorWithCode:(ConnectStatusCode)code andDetails:(id)details;

@end
