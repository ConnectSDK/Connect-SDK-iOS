//
// Created by Jeremy White on 5/28/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVPlayer.h>
#import "MediaPlayer.h"
#import "MediaControl.h"
#import "WebAppLauncher.h"

@class AirPlayService;

@interface AirPlayMirroredService : NSObject<MediaPlayer, MediaControl, WebAppLauncher>

- (instancetype) initWithAirPlayService:(AirPlayService *)service;

- (void) connect;
- (void) disconnect;

- (void) disconnectFromWebApp;

@property (nonatomic, readonly) AirPlayService *service;

@property (nonatomic, readonly) UIWindow *secondWindow;
@property (nonatomic, readonly) UIWebView *webAppWebView;
@property (nonatomic, readonly) AVPlayer *avPlayer;

@property (nonatomic, readonly) BOOL connecting;
@property (nonatomic, readonly) BOOL connected;

@end
