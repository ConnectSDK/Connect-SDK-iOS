//
//  CastService.h
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
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

#define kConnectSDKFlingServiceId @"MatchStick"

#import "ConnectSDK.h"
#import <Matchstick/Flint.h>
#import "FlintServiceChannel.h"

@interface FlintService : DeviceService <MSFKDeviceManagerDelegate, MediaPlayer, MediaControl, VolumeControl, WebAppLauncher>

/*! The MSFKDeviceManager that CastService is using internally to manage devices. */
@property (nonatomic, retain, readonly) MSFKDeviceManager *flintDeviceManager;

/*! The MSFKDevice object that FlingDevice is using internally for device information. */
@property (nonatomic, retain, readonly) MSFKDevice *flintDevice;

/*! The MSFKFlintChannel is used for app-to-app communication that is handling by the Connect SDK JavaScript Bridge. */
@property (nonatomic, retain, readonly) MSFKFlintChannel *flintServiceChannel;

/*! The MSFKMediaControlChannel that the FlingService is using to send media events to the connected web app. */
@property (nonatomic, retain, readonly) MSFKMediaControlChannel *flintMediaControlChannel;

// @cond INTERNAL
- (void) playMedia:(MSFKMediaInformation *)mediaInformation webAppId:(NSString *)webAppId success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure;
// @endcond

@end
