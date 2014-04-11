//
//  Launcher.h
//  Connect SDK
//
//  Created by Jeremy White on 12/16/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "AppInfo.h"
#import "ServiceSubscription.h"
#import "LaunchSession.h"

#define kLauncherAny @"Launcher.Any"

#define kLauncherApp @"Launcher.App"
#define kLauncherAppParams @"Launcher.App.Params"
#define kLauncherAppClose @"Launcher.App.Close"
#define kLauncherAppList @"Launcher.App.List"
#define kLauncherBrowser @"Launcher.Browser"
#define kLauncherBrowserParams @"Launcher.Browser.Params"
#define kLauncherHulu @"Launcher.Hulu"
#define kLauncherHuluParams @"Launcher.Hulu.Params"
#define kLauncherNetflix @"Launcher.Netflix"
#define kLauncherNetflixParams @"Launcher.Netflix.Params"
#define kLauncherYouTube @"Launcher.YouTube"
#define kLauncherYouTubeParams @"Launcher.YouTube.Params"
#define kLauncherAppState @"Launcher.AppState"
#define kLauncherAppStateSubscribe @"Launcher.AppState.Subscribe"
#define kLauncherRunningApp @"Launcher.RunningApp"
#define kLauncherRunningAppSubscribe @"Launcher.RunningApp.Subscribe"

#define kLauncherCapabilities @[\
    kLauncherApp,\
    kLauncherAppParams,\
    kLauncherAppClose,\
    kLauncherAppList,\
    kLauncherBrowser,\
    kLauncherBrowserParams,\
    kLauncherHulu,\
    kLauncherHuluParams,\
    kLauncherNetflix,\
    kLauncherNetflixParams,\
    kLauncherYouTube,\
    kLauncherYouTubeParams,\
    kLauncherAppState,\
    kLauncherAppStateSubscribe,\
    kLauncherRunningApp,\
    kLauncherRunningAppSubscribe\
]

@protocol Launcher <NSObject>

typedef void (^ AppInfoSuccessBlock)(AppInfo *appInfo);
typedef void (^ AppLaunchSuccessBlock)(LaunchSession *launchSession);
typedef void (^ AppListSuccessBlock)(NSArray *appList);
typedef void (^ AppStateSuccessBlock)(BOOL running, BOOL visible);

- (id<Launcher>) launcher;
- (CapabilityPriorityLevel) launcherPriority;

#pragma mark Launch & close
- (void)launchApp:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchAppWithInfo:(AppInfo *)appInfo success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchAppWithInfo:(AppInfo *)appInfo params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;

- (void)closeApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

#pragma mark App Info
- (void) getAppListWithSuccess:(AppListSuccessBlock)success failure:(FailureBlock)failure;

- (void) getRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure;

- (void)getAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribeAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure;

#pragma mark 3rd party launch
- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchYouTube:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchNetflix:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;

@end
