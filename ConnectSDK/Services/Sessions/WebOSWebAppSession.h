//
// Created by Jeremy White on 2/23/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebOSTVService.h"
#import "WebAppSession.h"

@interface WebOSWebAppSession : WebAppSession

@property (nonatomic, readonly) WebOSTVService *service;

@end
