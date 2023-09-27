//
//  AirPlayService.h
//  Connect SDK
//
//  Created by Jeremy White on 4/18/14.
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

#define kConnectSDKAirPlayServiceId @"AirPlay"

#import <Foundation/Foundation.h>
#import "DeviceService.h"
#import "AirPlayServiceHTTP.h"
#import "AirPlayServiceMirrored.h"
#import "MediaPlayer.h"
#import "MediaControl.h"
#import "WebAppLauncher.h"

/*!
 * The values in this enum type define what capabilities should be supported by the AirPlayService.
 */
typedef enum {
    /*! Enables support for web apps via Apple's [External Display](https://developer.apple.com/library/ios/documentation/WindowsViews/Conceptual/WindowAndScreenGuide/UsingExternalDisplay/UsingExternalDisplay.html) APIs */
    AirPlayServiceModeWebApp = 0,

    /*! Enables support for media (image, video, audio) by way of [HTTP commands](http://nto.github.io/AirPlay.html) */
    AirPlayServiceModeMedia
} AirPlayServiceMode;

/*!
 * ###Default functionality
 * Out of the box, AirPlayService will only support web app launching through AirPlay mirroring. AirPlayService also provides a Media mode, in which HTTP commands will be sent to the AirPlay device to play and control media files (image, video, audio). Due to certain limitations of the AirPlay protocol, you may only support web apps OR media capabilities through Connect SDK. You may still directly access AirPlay APIs through AVPlayer, MPMoviePlayerController, WKWebView, audio routing, etc.
 *
 * To set the capability mode for the AirPlayService, see the `setAirPlayServiceMode:` static method on the AirPlayService class.
 */
@interface AirPlayService : DeviceService <MediaPlayer, MediaControl, WebAppLauncher>

// @cond INTERNAL
@property (nonatomic, readonly) AirPlayServiceHTTP *httpService;
@property (nonatomic, readonly) AirPlayServiceMirrored *mirroredService;
// @endcond

/*!
 * Returns the current AirPlayServiceMode
 */
+ (AirPlayServiceMode) serviceMode;

/*!
 * Sets the AirPlayService mode. This property should be set before DiscoveryManager is set for the first time.
 */
+ (void) setAirPlayServiceMode:(AirPlayServiceMode)serviceMode;

@end
