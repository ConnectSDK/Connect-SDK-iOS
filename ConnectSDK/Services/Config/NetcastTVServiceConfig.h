//
// Created by Jeremy White on 12/30/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceConfig.h"

@interface NetcastTVServiceConfig : ServiceConfig <NSCoding>

@property (nonatomic, strong) NSString *pairingCode;

@end
