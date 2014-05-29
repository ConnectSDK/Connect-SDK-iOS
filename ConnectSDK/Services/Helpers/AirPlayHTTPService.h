//
// Created by Jeremy White on 5/28/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaPlayer.h"
#import "MediaControl.h"

@class AirPlayService;

@interface AirPlayHTTPService : NSObject <MediaPlayer, MediaControl>

- (instancetype) initWithAirPlayService:(AirPlayService *)service;
- (void) connect;
- (void) disconnect;

@property (nonatomic, readonly) AirPlayService *service;
@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;

@end
