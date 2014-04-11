//
//  WebOSService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

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

@class WebOSWebAppSession;

@interface WebOSTVService : DeviceService <NSCoding, Launcher, MediaPlayer, MediaControl, VolumeControl, TVControl, KeyControl, MouseControl, PowerControl, WebAppLauncher, ExternalInputControl, ToastControl, TextInputControl>

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

@property (nonatomic, strong, readonly) WebOSTVServiceMouse *mouseSocket;
@property (nonatomic, strong) WebOSTVServiceConfig *serviceConfig;
@property (nonatomic, strong) NSArray *permissions;

#pragma mark - Web app & app to app

// @cond INTERNAL
- (void)connectToWebApp:(WebOSWebAppSession *)webAppSession messageCallback:(WebAppMessageBlock)messageCallback success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)disconnectFromWebApp:(WebOSWebAppSession *)webAppSession;
- (int) sendMessage:(id)message toApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;
// @endcond

#pragma mark - System Info

// @cond INTERNAL
typedef void (^ ServiceListSuccessBlock)(NSArray *serviceList);
typedef void (^ SystemInfoSuccessBlock)(NSArray *featureList);

- (void)getServiceListWithSuccess:(ServiceListSuccessBlock)success failure:(FailureBlock)failure;
- (void)getSystemInfoWithSuccess:(SystemInfoSuccessBlock)success failure:(FailureBlock)failure;
// @endcond

@end
