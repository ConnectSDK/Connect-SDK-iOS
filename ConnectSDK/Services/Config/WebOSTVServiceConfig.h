//
//  WebOSTVServiceConfig.h
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceConfig.h"

@interface WebOSTVServiceConfig : ServiceConfig <NSCoding>

@property (nonatomic, strong) NSString *clientKey;
@property (nonatomic, strong) NSArray *SSLCertificates;

@end
