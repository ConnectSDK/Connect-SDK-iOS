//
// Created by Jeremy White on 6/18/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebAppSession.h"
#import "MultiScreenService.h"
#import <SamsungMultiscreen/SamsungMultiscreen.h>


@interface MultiScreenWebAppSession : WebAppSession

@property (nonatomic, readonly) WebAppMessageBlock messageHandler;
@property (nonatomic) MSApplication *application;
@property (nonatomic, readonly) MSChannel *channel;
@property (nonatomic, readonly) MultiScreenService *service;

@end
