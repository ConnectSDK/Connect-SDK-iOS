//
//  WebOSWebAppSession.m
//  Connect SDK
//
//  Created by Jeremy White on 2/23/14.
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

#import "WebOSWebAppSession_Private.h"

#import "ConnectError.h"
#import "SubtitleInfo.h"

#import "NSMutableDictionary+NilSafe.h"
#import "NSObject+FeatureNotSupported_Private.h"

static NSString *const kSubtitleTrackIdentifier = @"0";

@implementation WebOSWebAppSession
{
    ServiceSubscription *_playStateSubscription;
    ServiceSubscription *_messageSubscription;
    ServiceSubscription *_webAppPinnedSubscription;
    NSMutableDictionary *_activeCommands;

    SuccessBlock _connectSuccess;
    FailureBlock _connectFailure;

    int _UID;
}

@dynamic service;

- (instancetype)initWithLaunchSession:(LaunchSession *)launchSession service:(DeviceService *)service
{
    self = [super initWithLaunchSession:launchSession service:service];

    if (self)
    {
        _UID = 0;

        _activeCommands = [NSMutableDictionary new];
    }

    return self;
}

- (int) getNextId
{
    _UID = _UID + 1;
    return _UID;
}

- (NSString *) fullAppId
{
    if (!_fullAppId)
    {
        if (self.launchSession.sessionType != LaunchSessionTypeWebApp)
            _fullAppId = self.launchSession.appId;
        else
        {
            [self.service.appToAppIdMappings enumerateKeysAndObjectsUsingBlock:^(NSString *mappedFullAppId, NSString *mappedAppId, BOOL *stop) {
                if ([mappedAppId isEqualToString:self.launchSession.appId])
                {
                    _fullAppId = mappedFullAppId;
                    *stop = YES;
                }
            }];
        }
    }

    if (!_fullAppId)
        return self.launchSession.appId;
    else
        return _fullAppId;
}

#pragma mark - WebOSTVServiceSocketClientDelegate methods

- (void) socketDidConnect:(WebOSTVServiceSocketClient *)socket
{
    if (_connectSuccess)
        _connectSuccess(nil);

    _connectSuccess = nil;
    _connectFailure = nil;
}

- (void) socket:(WebOSTVServiceSocketClient *)socket didFailWithError:(NSError *)error
{
    _connected = NO;
    _appToAppSubscription = nil;

    if (_connectFailure)
    {
        if (!error)
            error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Unknown error connecting to web socket"];

        _connectFailure(error);
    }

    _connectSuccess = nil;
    _connectFailure = nil;

    [self disconnectFromWebApp];
}

- (void) socket:(WebOSTVServiceSocketClient *)socket didCloseWithError:(NSError *)error
{
    _connected = NO;
    _appToAppSubscription = nil;

    if (_connectFailure)
    {
        if (error)
            _connectFailure(error);
        else
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
                [self.delegate webAppSessionDidDisconnect:self];
        }
    }

    _connectSuccess = nil;
    _connectFailure = nil;

    [self disconnectFromWebApp];
}

- (BOOL) socket:(WebOSTVServiceSocketClient *)socket didReceiveMessage:(NSDictionary *)payload
{
    NSString *type = payload[@"type"];

    if ([type isEqualToString:@"p2p"])
    {
        NSString *fromAppId = payload[@"from"];

        if (![fromAppId isEqualToString:self.fullAppId])
            return NO;

        id message = payload[@"payload"];

        if ([message isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *messageJSON = (NSDictionary *)message;

            NSString *contentType = [messageJSON objectForKey:@"contentType"];
            NSRange contentTypeRange = [contentType rangeOfString:@"connectsdk."];

            if (contentType && contentTypeRange.location != NSNotFound)
            {
                NSString *payloadKey = [contentType substringFromIndex:contentTypeRange.length];

                if (!payloadKey || payloadKey.length == 0)
                    return NO;
                
                if ([payloadKey isEqualToString:@"media-error"]){
                    [self handleMediaEvent:messageJSON];
                }
                
                id messagePayload = [messageJSON objectForKey:payloadKey];

                if (!messagePayload)
                    return NO;

                if ([payloadKey isEqualToString:@"mediaEvent"])
                    [self handleMediaEvent:messagePayload];
                else if ([payloadKey isEqualToString:@"mediaCommandResponse"])
                    [self handleMediaCommandResponse:messagePayload];
            } else
            {
                [self handleMessage:messageJSON];
            }
        } else if ([message isKindOfClass:[NSString class]])
        {
            [self handleMessage:message];
        }

        return NO;
    }

    return YES;
}

#pragma mark - Subscription methods

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    {
        if (subscription == _playStateSubscription)
            _playStateSubscription = nil;
        else if (subscription == _messageSubscription)
            _messageSubscription = nil;
        else if (subscription == _webAppPinnedSubscription)
            _webAppPinnedSubscription = nil;
    }

    return -1;
}

#pragma mark - Message handlers

- (void) handleMediaEvent:(NSDictionary *)payload
{
    NSString *type = [payload objectForKey:@"type"];
    
    if(type == nil){
        NSString *errorMessage = [payload objectForKey:@"error"];
        if(errorMessage){
            [_playStateSubscription.failureCalls enumerateObjectsUsingBlock:^(FailureBlock failure, NSUInteger idx, BOOL *stop)
             {
                 failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:errorMessage]);
             }];
        }
    }
    else
    if ([type isEqualToString:@"playState"])
    {
        if (!_playStateSubscription)
            return;

        NSString *playStateString = [payload objectForKey:@"playState"];
        MediaControlPlayState playState = [self parsePlayState:playStateString];

        [_playStateSubscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger idx, BOOL *stop)
        {
            MediaPlayStateSuccessBlock mediaPlayStateSuccess = (MediaPlayStateSuccessBlock) success;

            if (mediaPlayStateSuccess)
                mediaPlayStateSuccess(playState);
        }];
    }
}

- (void) handleMediaCommandResponse:(NSDictionary *)payload
{
    NSString *requestId = [payload objectForKey:@"requestId"];

    ServiceCommand *command = [_activeCommands objectForKey:requestId];

    if (!command)
        return;

    NSString *error = [payload objectForKey:@"error"];

    if (error)
    {
        if (command.callbackError)
            command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:error]);
    } else
    {
        if (command.callbackComplete)
            command.callbackComplete(payload);
    }

    [_activeCommands removeObjectForKey:requestId];
}

- (void) handleMessage:(id)message
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(webAppSession:didReceiveMessage:)])
        [self.delegate webAppSession:self didReceiveMessage:message];
}

- (MediaControlPlayState) parsePlayState:(NSString *)playStateString
{
    MediaControlPlayState playState = MediaControlPlayStateUnknown;

    if ([playStateString isEqualToString:@"playing"])
        playState = MediaControlPlayStatePlaying;
    else if ([playStateString isEqualToString:@"paused"])
        playState = MediaControlPlayStatePaused;
    else if ([playStateString isEqualToString:@"idle"])
        playState = MediaControlPlayStateIdle;
    else if ([playStateString isEqualToString:@"buffering"])
        playState = MediaControlPlayStateBuffering;
    else if ([playStateString isEqualToString:@"finished"])
        playState = MediaControlPlayStateFinished;

    return playState;
}

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connect:NO success:success failure:failure];
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connect:YES success:success failure:failure];
}

- (void) connect:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.socket && self.socket.socket.readyState == LGSR_CONNECTING)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"You have a connect request pending, please wait until it has finished"]);

        return;
    }

    if (self.connected)
    {
        if (success)
            success(nil);

        return;
    }

    if (!_messageSubscription)
        _messageSubscription = [ServiceSubscription subscriptionWithDelegate:nil target:nil payload:nil callId:-1];

    __weak WebOSWebAppSession *weakSelf = self;

    _connectFailure = ^(NSError *error) {
        if (weakSelf)
        {
            WebOSWebAppSession *strongSelf = weakSelf;

            [strongSelf disconnectFromWebApp];
        }

        if (failure)
        {
            if (!error)
                error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Unknown error connecting to web app"];
            failure(error);
        }
    };

    __weak FailureBlock weakConnectFailure = _connectFailure;

    _connectSuccess = ^(id socketResponseObject) {
        if (!weakSelf || !weakConnectFailure)
            return;

        WebOSWebAppSession *strongSelf = weakSelf;
        FailureBlock strongConnectFailure = weakConnectFailure;

        [strongSelf.service connectToWebApp:strongSelf joinOnly:joinOnly success:^(id connectResponseObject)
        {
            strongSelf.connected = YES;

            if (success)
                success(nil);
        } failure:strongConnectFailure];
    };

    if (self.socket && self.socket.connected)
    {
        _connectSuccess(nil);
    } else
    {
        _socket = [self createSocketWithService:self.service];
        _socket.delegate = self;
        [_socket connect];
    }
}

- (void)sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message || message.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send an empty message"]);

        return;
    }

    [self sendP2PMessage:message success:success failure:failure];
}

- (void)sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message || message.count == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send an empty message"]);

        return;
    }

    [self sendP2PMessage:message success:success failure:failure];
}

- (void) sendP2PMessage:(id)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *payload = @{
            @"type" : @"p2p",
            @"to" : self.fullAppId,
            @"payload" : message
    };

    if (self.connected)
    {
        [self.socket sendDictionaryOverSocket:payload];

        if (success)
            success(nil);
    } else
    {
        [self connectWithSuccess:^(id responseObject) {
            [self sendP2PMessage:message success:success failure:failure];

            if (success)
                success(nil);
        } failure:failure];
    }
}

- (void) disconnectFromWebApp
{
    _connected = NO;

    _connectSuccess = nil;
    _connectFailure = nil;

    [_appToAppSubscription.failureCalls removeAllObjects];
    [_appToAppSubscription.successCalls removeAllObjects];
    _appToAppSubscription = nil;

    self.socket.delegate = nil;
    [self.socket disconnectWithError:nil];
    _socket = nil;

    if (self.delegate && [self.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
        dispatch_on_main(^{ [self.delegate webAppSessionDidDisconnect:self]; });
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    _activeCommands = [NSMutableDictionary new];

    [_playStateSubscription unsubscribe];
    _playStateSubscription = nil;

    _messageSubscription = nil;
    _webAppPinnedSubscription = nil;

    [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
}

- (void)pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher pinWebApp:webAppId success:success failure:failure];
}

- (void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher unPinWebApp:webAppId success:success failure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher isWebAppPinned:webAppId success:success failure:failure];
}

- (ServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    _webAppPinnedSubscription = [self.service.webAppLauncher subscribeIsWebAppPinned:webAppId success:success failure:failure];
    return _webAppPinnedSubscription;
}

#pragma mark - Media Player

- (id <MediaPlayer>) mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
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
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];
    
    NSDictionary *message = @{
                              @"contentType" : @"connectsdk.mediaCommand",
                              @"mediaCommand" : @{
                                      @"type" : @"displayImage",
                                      @"mediaURL" : ensureString(mediaInfo.url.absoluteString),
                                      @"iconURL" : ensureString(iconURL.absoluteString),
                                      @"title" : ensureString(mediaInfo.title),
                                      @"description" : ensureString(mediaInfo.description),
                                      @"mimeType" : ensureString(mediaInfo.mimeType),
                                      @"requestId" : requestId
                                      }
                              };
    
    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:self.launchSession andMediaControl:self.mediaControl];
        if(success){
            success(launchObject);
        }
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];
    
    [self sendJSON:message success:nil failure:failure];
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
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSMutableDictionary *const mediaCommand = [@{
        @"type" : @"playMedia",
        @"mediaURL" : ensureString(mediaInfo.url.absoluteString),
        @"iconURL" : ensureString(iconURL.absoluteString),
        @"title" : ensureString(mediaInfo.title),
        @"description" : ensureString(mediaInfo.description),
        @"mimeType" : ensureString(mediaInfo.mimeType),
        @"shouldLoop" : @(shouldLoop),
        @"requestId" : requestId,
    } mutableCopy];
    if (mediaInfo.subtitleInfo) {
        mediaCommand[@"subtitles"] = [self subtitlesDictionaryFromSubtitleInfo:mediaInfo.subtitleInfo];
    }

    NSDictionary *message = @{@"contentType" : @"connectsdk.mediaCommand",
                              @"mediaCommand" : mediaCommand};

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:self.launchSession andMediaControl:self.mediaControl andPlayListControl:self.playListControl];
        if(success){
            success(launchObject);
        }
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];
    
    [self sendJSON:message success:nil failure:failure];
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self closeWithSuccess:success failure:failure];
}

#pragma mark - Media Control

- (id <MediaControl>) mediaControl
{
    return self;
}

- (CapabilityPriorityLevel) mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"seek",
                    @"position" : @(position),
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"getPosition",
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSString *positionString = [responseObject objectForKey:@"position"];
        NSTimeInterval position = 0;

        if (positionString && ![positionString isKindOfClass:[NSNull class]])
            position = [positionString intValue];

        if (success)
            success(position);
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"getDuration",
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        NSString *durationString = [responseObject objectForKey:@"duration"];
        NSTimeInterval duration = 0;

        if (durationString && ![durationString isKindOfClass:[NSNull class]])
            duration = [durationString intValue];

        if (success)
            success(duration);
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"getPlayState",
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSString *playStateString = [responseObject objectForKey:@"playState"];
        MediaControlPlayState playState = [self parsePlayState:playStateString];

        if (success)
            success(playState);
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (!_playStateSubscription)
        _playStateSubscription = [ServiceSubscription subscriptionWithDelegate:nil target:nil payload:nil callId:-1];

    if (!self.connected)
        [self connectWithSuccess:nil failure:failure];

    if (![_playStateSubscription.successCalls containsObject:success])
        [_playStateSubscription addSuccess:success];

    if (![_playStateSubscription.failureCalls containsObject:failure])
        [_playStateSubscription addFailure:failure];

    return _playStateSubscription;
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
}

#pragma mark - Playlist Control

- (id <PlayListControl>) playListControl
{
    return self;
}

- (CapabilityPriorityLevel)playListControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)playNextWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSMutableDictionary *mediaCommand = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                        @"type" : @"playNext"
                                                                                        }];
    [self sendMediaCommand:mediaCommand success:success failure:failure];
}

- (void)playPreviousWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure{
    NSMutableDictionary *mediaCommand = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                        @"type" : @"playPrevious"
                                                                                        }];
    [self sendMediaCommand:mediaCommand success:success failure:failure];
}

- (void)jumpToTrackWithIndex:(NSInteger)index success:(SuccessBlock)success failure:(FailureBlock)failure{
    NSMutableDictionary *mediaCommand = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                        @"type" : @"jumpToTrack",
                                                                                        @"index" : [NSNumber numberWithInteger:index]
                                                                                        }];
    [self sendMediaCommand:mediaCommand success:success failure:failure];
}

- (void)sendMediaCommand:(NSMutableDictionary *)mediaCommand success:(SuccessBlock)success failure:(FailureBlock)failure{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];
    [mediaCommand setObject:requestId forKey:@"requestId"];
     NSDictionary *message = [self messageForMediaCommand:mediaCommand];
    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        if (success)
            success(responseObject);
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];
    
    [self sendJSON:message success:nil failure:failure];
}

- (NSDictionary *)messageForMediaCommand:(NSDictionary *)mediaCommand {
    NSDictionary *message = @{
                              @"contentType" : @"connectsdk.mediaCommand",
                              @"mediaCommand" : mediaCommand
                              };
    return message;
}

#pragma mark - Private Methods

- (WebOSTVServiceSocketClient *)createSocketWithService:(WebOSTVService *)service {
    return [[WebOSTVServiceSocketClient alloc] initWithService:service];
}

- (nonnull NSDictionary *)subtitlesDictionaryFromSubtitleInfo:(nonnull SubtitleInfo *)subtitleInfo {
    NSMutableDictionary *subtitleDict = [@{
        @"id": kSubtitleTrackIdentifier,
        @"source": subtitleInfo.url.absoluteString,
    } mutableCopy];
    [subtitleDict setNullableObject:subtitleInfo.language forKey:@"language"];
    [subtitleDict setNullableObject:subtitleInfo.label forKey:@"label"];

    return @{
        @"tracks": @[[subtitleDict copy]],
        @"enabled": kSubtitleTrackIdentifier,
    };
}

@end
