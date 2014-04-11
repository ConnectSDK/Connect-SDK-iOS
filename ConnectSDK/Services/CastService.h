//
//  CastService.h
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <ConnectSDK/ConnectSDK.h>
#import <GoogleCast/GoogleCast.h>
#import "CastServiceChannel.h"

@interface CastService : DeviceService <GCKDeviceManagerDelegate, GCKMediaControlChannelDelegate, MediaPlayer, MediaControl, VolumeControl, WebAppLauncher>

@property (nonatomic, retain, readonly) GCKDeviceManager *castDeviceManager;
@property (nonatomic, retain, readonly) GCKDevice *castDevice;
@property (nonatomic, retain, readonly) CastServiceChannel *castServiceChannel;
@property (nonatomic, retain, readonly) GCKMediaControlChannel *castMediaControlChannel;

@end
