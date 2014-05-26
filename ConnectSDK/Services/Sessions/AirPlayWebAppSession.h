//
// Created by Jeremy White on 4/24/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebAppSession.h"
#import "AirPlayService.h"


@interface AirPlayWebAppSession : WebAppSession

@property (nonatomic, readonly) AirPlayService *service;

@property (nonatomic, readonly) WebAppMessageBlock messageHandler;

@end
