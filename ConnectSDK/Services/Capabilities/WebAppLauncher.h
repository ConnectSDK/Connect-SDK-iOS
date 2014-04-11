//
// Created by Jeremy White on 12/16/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "LaunchSession.h"
#import "WebAppSession.h"
#import "MediaControl.h"

#define kWebAppLauncherAny @"WebAppLauncher.Any"

#define kWebAppLauncherLaunch @"WebAppLauncher.Launch"
#define kWebAppLauncherLaunchParams @"WebAppLauncher.Launch.Params"
#define kWebAppLauncherMessageSend @"WebAppLauncher.Message.Send"
#define kWebAppLauncherMessageReceive @"WebAppLauncher.Message.Receive"
#define kWebAppLauncherMessageSendJSON @"WebAppLauncher.Message.Send.JSON"
#define kWebAppLauncherMessageReceiveJSON @"WebAppLauncher.Message.Receive.JSON"
#define kWebAppLauncherClose @"WebAppLauncher.Close"

#define kWebAppLauncherCapabilities @[\
    kWebAppLauncherLaunch,\
    kWebAppLauncherLaunchParams,\
    kWebAppLauncherMessageSend,\
    kWebAppLauncherMessageReceive,\
    kWebAppLauncherMessageSendJSON,\
    kWebAppLauncherMessageReceiveJSON,\
    kWebAppLauncherClose\
]

@protocol WebAppLauncher <NSObject>

typedef void (^ WebAppLaunchSuccessBlock)(WebAppSession *webAppSession);

- (id<WebAppLauncher>) webAppLauncher;
- (CapabilityPriorityLevel) webAppLauncherPriority;

- (void) launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void) closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

@end

