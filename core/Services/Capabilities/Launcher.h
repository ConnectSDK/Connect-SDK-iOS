//
//  Launcher.h
//  Connect SDK
//
//  Created by Jeremy White on 12/16/13.
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
#define kLauncherAppStore @"Launcher.AppStore"
#define kLauncherAppStoreParams @"Launcher.AppStore.Params"
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
    kLauncherAppStore,\
    kLauncherAppStoreParams,\
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

/*!
 * Success block that is called upon requesting info about the current running app.
 *
 * @param appInfo Object containing info about the running app
 */
typedef void (^ AppInfoSuccessBlock)(AppInfo *appInfo);

/*!
 * Success block that is called upon successfully launching an app.
 *
 * @param LaunchSession Object containing important information about the app's launch session
 */
typedef void (^ AppLaunchSuccessBlock)(LaunchSession *launchSession);

/*!
 * Success block that is called upon successfully getting the app list.
 *
 * @param appList Array containing an AppInfo object for each available app on the device
 */
typedef void (^ AppListSuccessBlock)(NSArray *appList);

/*!
 * Success block that is called upon successfully getting an app's state.
 *
 * @param running Whether the app is currently running
 * @param visible Whether the app is currently visible on the screen
 */
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

#pragma mark Helpers for deep linking
- (void)launchAppStore:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchYouTube:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchYouTube:(NSString *)contentId startTime:(float)startTime success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;

// TODO: add app store deep linking

// @cond INTERNAL
- (void)launchNetflix:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
// @endcond

@end
