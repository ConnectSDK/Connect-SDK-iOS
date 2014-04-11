//
//  ConnectError.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 10/4/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ConnectError.h"

NSString *ConnectErrorDomain = @"com.lge.connectsdk.error";

@implementation ConnectError

+ (NSError *) generateErrorWithCode:(ConnectStatusCode)code andDetails:(id)details
{
    NSString *errorMessage;
    
    switch (code)
    {
        case ConnectStatusCodeTvError:
            errorMessage = [NSString stringWithFormat:@"API error: %@", details];
            break;
            
        case ConnectStatusCodeCertificateError:
            errorMessage = [NSString stringWithFormat:@"Invalid server certificate"];
            break;
            
        case ConnectStatusCodeSocketError:
            errorMessage = [NSString stringWithFormat:@"Web Socket Error: %@", details];
            break;
            
        case ConnectStatusCodeNotSupported:
            errorMessage = [NSString stringWithFormat:@"This feature is not supported."];
            break;
        
        default:
            if (details)
                errorMessage = [NSString stringWithFormat:@"A generic error occured: %@", details];
            else
                errorMessage = [NSString stringWithFormat:@"A generic error occured"];
    }
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:ConnectErrorDomain code:code userInfo:userInfo];

}

@end
