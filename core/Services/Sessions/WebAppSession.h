//
//  WebAppSession.h
//  Connect SDK
//
//  Created by Jeremy White on 2/21/14.
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
#import "DeviceService.h"
#import "MediaPlayer.h"
#import "MediaControl.h"
#import "ServiceCommandDelegate.h"
#import "LaunchSession.h"
#import "WebAppSessionDelegate.h"

/*! Status of the web app */
typedef enum {
    /*! Web app status is unknown */
    WebAppStatusUnknown,

    /*! Web app is running and in the foreground */
    WebAppStatusOpen,

    /*! Web app is running and in the background */
    WebAppStatusBackground,

    /*! Web app is in the foreground but has not started running yet */
    WebAppStatusForeground,

    /*! Web app is not running and is not in the foreground or background */
    WebAppStatusClosed
} WebAppStatus;


/*!
 * ###Overview
 * When a web app is launched on a first screen device, there are certain tasks that can be performed with that web app. WebAppSession serves as a second screen reference of the web app that was launched. It behaves similarly to LaunchSession, but is not nearly as static.
 *
 * ###In Depth
 * On top of maintaining session information (contained in the launchSession property), WebAppSession provides access to a number of capabilities.
 * - MediaPlayer
 * - MediaControl
 * - Bi-directional communication with web app
 *
 * MediaPlayer and MediaControl are provided to allow for the most common first screen use cases -- a media player (audio, video, & images).
 *
 * The Connect SDK JavaScript Bridge has been produced to provide normalized support for these capabilities across protocols (Chromecast, webOS, etc).
 */
@interface WebAppSession : NSObject <ServiceCommandDelegate, MediaPlayer, MediaControl, JSONObjectCoding, PlayListControl>

// @cond INTERNAL
// This is only being used in WebOSWebAppSession, but could be useful in other places in the future
typedef void (^ WebAppMessageBlock)(id message);
// @endcond

/*!
 * Success block that is called upon successfully getting a web app's status.
 *
 * @param status The current running & foreground status of the web app
 */
typedef void (^ WebAppStatusBlock)(WebAppStatus status);

/*!
 * Success block that is called upon successfully getting a web app's status.
 *
 * @param status The current running & foreground status of the web app
 */
typedef void (^ WebAppPinStatusBlock)(BOOL status);

/*!
 * LaunchSession object containing key session information. Much of this information is required for web app messaging & closing the web app.
 */
@property (nonatomic, strong) LaunchSession *launchSession;

/*!
 * DeviceService that was responsible for launching this web app.
 */
@property (nonatomic, weak, readonly) DeviceService *service;

/*!
 * Instantiates a WebAppSession object with all the information necessary to interact with a web app.
 *
 * @param launchSession LaunchSession containing info about the web app session
 * @param service DeviceService that was responsible for launching this web app
 */
- (instancetype) initWithLaunchSession:(LaunchSession *)launchSession service:(DeviceService *)service;

/*!
 * Subscribes to changes in the web app's status.
 *
 * @param success (optional) WebAppStatusBlock to be called on app status change
 * @param failure (optional) FailureBlock to be called on failure
 */
- (ServiceSubscription *) subscribeWebAppStatus:(WebAppStatusBlock)success failure:(FailureBlock)failure;

/*!
 * Join an active web app without launching/relaunching. If the app is not running/joinable, the failure block will be called immediately.
 *
 * @param success (optional) SuccessBlock to be called on join success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

/*!
 * Closes the web app on the first screen device.
 *
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

#pragma mark - Connection handling

/*!
 * Establishes a communication channel with the web app.
 *
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

/*!
 * Closes any open communication channel with the web app.
 */
- (void) disconnectFromWebApp;

/*!
 * Pin the web app on the launcher.
 *
 * @param webAppId NSString webAppId to be pinned.
 */
- (void)pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure;

/*!
 * UnPin the web app on the launcher.
 *
 * @param webAppId NSString webAppId to be unpinned.
 */
- (void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure;

/*!
 * To check if the web app is pinned or not
 */
- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure;

#pragma mark - Communication

/*!
 * When messages are received from a web app, they are parsed into the appropriate object type (string vs JSON/NSDictionary) and routed to the WebAppSessionDelegate.
 */
@property (nonatomic, strong) id<WebAppSessionDelegate> delegate;

/*!
 * Sends a simple string to the web app. The Connect SDK JavaScript Bridge will receive this message and hand it off as a string object.
 *
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure;

/*!
 * Sends a JSON object to the web app. The Connect SDK JavaScript Bridge will receive this message and hand it off as a JavaScript object.
 *
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
