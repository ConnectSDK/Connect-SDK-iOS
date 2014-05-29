//
//  AirPlayService.m
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

#import "AirPlayService.h"
#import "ConnectError.h"


@interface AirPlayService (Private) <UIWebViewDelegate, ServiceCommandDelegate, UIAlertViewDelegate>

@end

static AirPlayServiceMode airPlayServiceMode;


@implementation AirPlayService
{
    AirPlayHTTPService *_httpService;
    AirPlayMirroredService *_mirroredService;
}

+ (void) setAirPlayServiceMode:(AirPlayServiceMode)serviceMode
{
    airPlayServiceMode = serviceMode;
}

+ (AirPlayServiceMode) serviceMode
{
    return airPlayServiceMode;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
        @"serviceId" : kConnectSDKAirPlayServiceId,
        @"zeroconf" : @{
                @"filter" : @"_airplay._tcp"
        }
    };
}

- (void) updateCapabilities
{
    NSArray *caps = [NSArray array];

    caps = [caps arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
    caps = [caps arrayByAddingObjectsFromArray:kMediaControlCapabilities];

    if ([AirPlayService serviceMode] == AirPlayServiceModeMirrored
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        caps = [caps arrayByAddingObjectsFromArray:kWebAppLauncherCapabilities];

    [super setCapabilities:caps];
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeMirrored
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        [self.mirroredService connect];

    if ([AirPlayService serviceMode] == AirPlayServiceModeHTTP
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        [self.httpService connect];

     // delegate will receive connected message from either mirroredService or httpService, depending on the value AirPlayService serviceMode property
}

- (void) disconnect
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeMirrored
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        [self.mirroredService disconnect];

    if ([AirPlayService serviceMode] == AirPlayServiceModeHTTP
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        [self.httpService disconnect];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (BOOL) connected
{
    switch ([AirPlayService serviceMode])
    {
        case AirPlayServiceModeMirrored:
            return self.mirroredService.connected;

        case AirPlayServiceModeHTTP:
            return self.httpService.connected;

        case AirPlayServiceModeMixed:
            return self.mirroredService.connected && self.httpService.connected;

        default:
            return NO;
    }
}

- (AirPlayHTTPService *) httpService
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeMirrored)
        return nil;

    if (!_httpService)
        _httpService = [[AirPlayHTTPService alloc] initWithAirPlayService:self];

    return _httpService;
}

- (AirPlayMirroredService *) mirroredService
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeHTTP)
        return nil;

    if (!_mirroredService)
        _mirroredService = [[AirPlayMirroredService alloc] initWithAirPlayService:self];

    return _mirroredService;
}

#pragma mark - MediaPlayer

- (id <MediaPlayer>) mediaPlayer
{
    id<MediaPlayer> player = self.mirroredService.mediaPlayer;

    if ([AirPlayService serviceMode] == AirPlayServiceModeHTTP
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        player = self.httpService.mediaPlayer;

    return player;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return self.mediaPlayer.mediaPlayerPriority;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaPlayer displayImage:imageURL iconURL:iconURL title:description description:description mimeType:description success:success failure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaPlayer playMedia:iconURL iconURL:iconURL title:description description:description mimeType:description shouldLoop:shouldLoop success:success failure:failure];
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaPlayer closeMedia:launchSession success:success failure:failure];
}

#pragma mark - Media Control

- (id <MediaControl>) mediaControl
{
    id<MediaControl> control = self.mirroredService.mediaControl;

    if ([AirPlayService serviceMode] == AirPlayServiceModeHTTP
            || [AirPlayService serviceMode] == AirPlayServiceModeMixed)
        control = self.httpService.mediaControl;

    return control;
}

- (CapabilityPriorityLevel) mediaControlPriority
{
    return self.mediaControl.mediaControlPriority;
}

- (void) playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl playWithSuccess:success failure:failure];
}

- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl pauseWithSuccess:success failure:failure];
}

- (void) stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl stopWithSuccess:success failure:failure];
}

- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl rewindWithSuccess:success failure:failure];
}

- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl fastForwardWithSuccess:success failure:failure];
}

- (void) getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl getDurationWithSuccess:success failure:failure];
}

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl getPlayStateWithSuccess:success failure:failure];
}

- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl getPositionWithSuccess:success failure:failure];
}

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl seek:position success:success failure:failure];
}

- (ServiceSubscription *) subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    return [self.mediaControl subscribePlayStateWithSuccess:success failure:failure];;
}

#pragma mark - Helpers

- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (launchSession.sessionType == LaunchSessionTypeWebApp)
    {
        [self.webAppLauncher closeWebApp:launchSession success:success failure:failure];
    } else if (launchSession.sessionType == LaunchSessionTypeMedia)
    {
        [self.mediaPlayer closeMedia:launchSession success:success failure:failure];
    } else
    {
        if (failure)
            dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find DeviceService responsible for closing this LaunchSession"]); });
    }
}

#pragma mark - WebAppLauncher

- (id <WebAppLauncher>) webAppLauncher
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeHTTP)
        return nil;
    else
        return self.mirroredService.webAppLauncher;
}

- (CapabilityPriorityLevel) webAppLauncherPriority
{
    return self.webAppLauncher.webAppLauncherPriority;
}

- (void) launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:params relaunchIfRunning:relaunchIfRunning success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId relaunchIfRunning:YES success:success failure:failure];
}

- (void) joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher joinWebApp:webAppLaunchSession success:success failure:failure];
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher joinWebAppWithId:webAppId success:success failure:failure];
}

- (void) closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher closeWebApp:launchSession success:success failure:failure];
}

@end
