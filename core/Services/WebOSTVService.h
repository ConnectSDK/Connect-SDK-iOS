//
//  WebOSService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#define kConnectSDKWebOSTVServiceId @"webOS TV"

#import <UIKit/UIKit.h>
#import "DeviceService.h"
#import "Launcher.h"
#import "WebOSTVServiceConfig.h"
#import "MediaPlayer.h"
#import "VolumeControl.h"
#import "TVControl.h"
#import "KeyControl.h"
#import "WebOSTVServiceMouse.h"
#import "MouseControl.h"
#import "PowerControl.h"
#import "MediaControl.h"
#import "WebAppLauncher.h"
#import "ToastControl.h"
#import "ExternalInputControl.h"
#import "TextInputControl.h"
#import "PlayListControl.h"
#import "ScreenMirroringControl.h"
#import "RemoteCameraControl.h"

@class WebOSWebAppSession;
@class WebOSTVServiceSocketClient;

@interface WebOSTVService : DeviceService <Launcher, MediaPlayer, MediaControl, VolumeControl, TVControl, KeyControl, MouseControl, PowerControl, WebAppLauncher, ExternalInputControl, ToastControl, TextInputControl, PlayListControl, ScreenMirroringControl, RemoteCameraControl>

// @cond INTERNAL
typedef enum {
    LAUNCH = 0,
    LAUNCH_WEBAPP,
    APP_TO_APP,
    CONTROL_AUDIO,
    CONTROL_INPUT_MEDIA_PLAYBACK
} WebOSTVServiceOpenPermission;

#define kWebOSTVServiceOpenPermissions @[@"LAUNCH", @"LAUNCH_WEBAPP", @"APP_TO_APP", @"CONTROL_AUDIO", @"CONTROL_INPUT_MEDIA_PLAYBACK"]

typedef enum {
    CONTROL_POWER = 0,
    READ_INSTALLED_APPS,
    CONTROL_DISPLAY,
    CONTROL_INPUT_JOYSTICK,
    CONTROL_INPUT_MEDIA_RECORDING,
    CONTROL_INPUT_TV,
    READ_INPUT_DEVICE_LIST,
    READ_NETWORK_STATE,
    READ_TV_CHANNEL_LIST,
    WRITE_NOTIFICATION_TOAST
} WebOSTVServiceProtectedPermission;

#define kWebOSTVServiceProtectedPermissions @[@"CONTROL_POWER", @"READ_INSTALLED_APPS", @"CONTROL_DISPLAY", @"CONTROL_INPUT_JOYSTICK", @"CONTROL_INPUT_MEDIA_RECORDING", @"CONTROL_INPUT_TV", @"READ_INPUT_DEVICE_LIST", @"READ_NETWORK_STATE", @"READ_TV_CHANNEL_LIST", @"WRITE_NOTIFICATION_TOAST"]

typedef enum {
    CONTROL_INPUT_TEXT = 0,
    CONTROL_MOUSE_AND_KEYBOARD,
    READ_CURRENT_CHANNEL,
    READ_RUNNING_APPS
} WebOSTVServicePersonalActivityPermission;

#define kWebOSTVServicePersonalActivityPermissions @[@"CONTROL_INPUT_TEXT", @"CONTROL_MOUSE_AND_KEYBOARD", @"READ_CURRENT_CHANNEL", @"READ_RUNNING_APPS"]

@property (nonatomic, strong, readonly) WebOSTVServiceSocketClient *socket;
@property (nonatomic, strong, readonly) WebOSTVServiceMouse *mouseSocket;
/// The base class' @c serviceConfig property downcast to
/// @c WebOSTVServiceConfig class if possible, or nil.
@property (nonatomic, strong, readonly) WebOSTVServiceConfig *webOSTVServiceConfig;
@property (nonatomic, strong) NSArray *permissions;
@property (nonatomic, readonly) NSDictionary *appToAppIdMappings;
@property (nonatomic, readonly) NSDictionary *webAppSessions;
// @endcond

#pragma mark - Web app & app to app

// @cond INTERNAL
- (void) connectToWebApp:(WebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure;
// @endcond

#pragma mark - Native app to app

// @cond INTERNAL
- (void) connectToApp:(NSString *)appId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void) joinApp:(NSString *)appId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void) connectToApp:(WebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure;
// @endcond

#pragma mark - System Info

// @cond INTERNAL
typedef void (^ ServiceListSuccessBlock)(NSArray *serviceList);
typedef void (^ SystemInfoSuccessBlock)(NSArray *featureList);

- (void)getServiceListWithSuccess:(ServiceListSuccessBlock)success failure:(FailureBlock)failure;
- (void)getSystemInfoWithSuccess:(SystemInfoSuccessBlock)success failure:(FailureBlock)failure;
// @endcond

@end
