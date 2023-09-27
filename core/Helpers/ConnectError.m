//
//  ConnectError.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 10/4/13.
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

#import "ConnectError.h"

NSString *const ConnectErrorDomain = @"com.lge.connectsdk.error";

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
