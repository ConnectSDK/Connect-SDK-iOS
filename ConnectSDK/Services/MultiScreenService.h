//
// Created by Jeremy White on 6/16/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SamsungMultiscreen/SamsungMultiscreen.h>
#import "DeviceService.h"
#import "WebAppLauncher.h"

#define kConnectSDKMultiScreenTVServiceId @"Samsung MultiScreen"


@interface MultiScreenService : DeviceService <MediaPlayer, WebAppLauncher>

@property (nonatomic, readonly) MSDevice *device;

@end
