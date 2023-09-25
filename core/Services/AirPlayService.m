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

#import "AirPlayService_Private.h"
#import "ConnectError.h"

#import "NSObject+FeatureNotSupported_Private.h"

@interface AirPlayService () <WKNavigationDelegate, ServiceCommandDelegate, UIAlertViewDelegate>

@end

static AirPlayServiceMode airPlayServiceMode;

@implementation AirPlayService

@synthesize httpService = _httpService;
@synthesize mirroredService = _mirroredService;

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

    if ([AirPlayService serviceMode] == AirPlayServiceModeMedia)
    {
        caps = [caps arrayByAddingObjectsFromArray:@[
                kMediaPlayerDisplayImage,
                kMediaPlayerPlayVideo,
                kMediaPlayerPlayAudio,
                kMediaPlayerClose,
                kMediaPlayerMetaDataMimeType
        ]];

        caps = [caps arrayByAddingObjectsFromArray:@[
                kMediaControlPlay,
                kMediaControlPause,
                kMediaControlStop,
                kMediaControlRewind,
                kMediaControlFastForward,
                kMediaControlPlayState,
                kMediaControlDuration,
                kMediaControlPosition,
                kMediaControlSeek
        ]];
    } else if ([AirPlayService serviceMode] == AirPlayServiceModeWebApp)
    {
        caps = [caps arrayByAddingObjectsFromArray:@[
                kWebAppLauncherLaunch,
                kWebAppLauncherMessageSend,
                kWebAppLauncherMessageReceive,
                kWebAppLauncherMessageSendJSON,
                kWebAppLauncherMessageReceiveJSON,
                kWebAppLauncherClose,
                kWebAppLauncherConnect,
                kWebAppLauncherJoin,
                kWebAppLauncherDisconnect
        ]];
    }

    [super setCapabilities:caps];
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeWebApp)
        [self.mirroredService connect];

    if ([AirPlayService serviceMode] == AirPlayServiceModeMedia)
        [self.httpService connect];

     // delegate will receive connected message from either mirroredService or httpService, depending on the value AirPlayService serviceMode property
}

- (void) disconnect
{
    if ([AirPlayService serviceMode] == AirPlayServiceModeWebApp && self.mirroredService.connected)
        [self.mirroredService disconnect];

    if ([AirPlayService serviceMode] == AirPlayServiceModeMedia && self.httpService.connected)
        [self.httpService disconnect];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (BOOL) connected
{
    switch ([AirPlayService serviceMode])
    {
        case AirPlayServiceModeWebApp:
            return self.mirroredService.connected;

        case AirPlayServiceModeMedia:
            return self.httpService.connected;

        default:
            return NO;
    }
}

- (AirPlayServiceHTTP *) httpService
{
    if (!_httpService)
        _httpService = [self createHTTPService];

    return _httpService;
}

- (AirPlayServiceMirrored *) mirroredService
{
    if (!_mirroredService)
        _mirroredService = [[AirPlayServiceMirrored alloc] initWithAirPlayService:self];

    return _mirroredService;
}

#pragma mark - MediaPlayer

- (id <MediaPlayer>) mediaPlayer
{
    return self.httpService.mediaPlayer;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return self.mediaPlayer.mediaPlayerPriority;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:imageURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self displayImageWithMediaInfo:mediaInfo success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) displayImage:(MediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) displayImageWithMediaInfo:(MediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaPlayer displayImageWithMediaInfo:mediaInfo success:success failure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    ImageInfo *imageInfo = [[ImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    [self playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:^(MediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) playMedia:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void) playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:success failure:failure];
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaPlayer closeMedia:launchSession success:success failure:failure];
}

#pragma mark - Media Control

- (id <MediaControl>) mediaControl
{
    return self.httpService.mediaControl;
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
    return [self.mediaControl subscribePlayStateWithSuccess:success failure:failure];
}

- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success
                            failure:(FailureBlock)failure {
    [self.mediaControl getMediaMetaDataWithSuccess:success failure:failure];
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
   return [self.mediaControl subscribeMediaInfoWithSuccess:success failure:failure];
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

- (void) pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

-(void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
}

#pragma mark - Private

- (AirPlayServiceHTTP *)createHTTPService {
    return [[AirPlayServiceHTTP alloc] initWithAirPlayService:self];
}

@end
