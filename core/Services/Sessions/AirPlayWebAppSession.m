//
//  AirPlayWebAppSession.m
//  Connect SDK
//
//  Created by Jeremy White on 4/24/14.
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

#import "AirPlayWebAppSession.h"
#import "ConnectError.h"
#import "ConnectUtil.h"
#import "MediaLaunchObject.h"

#import "NSObject+FeatureNotSupported_Private.h"

@interface AirPlayWebAppSession () <ServiceCommandDelegate>
{
    ServiceSubscription *_playStateSubscription;
    NSMutableDictionary *_activeCommands;

    int _UID;
}

@end

@implementation AirPlayWebAppSession
{
    ServiceSubscription *_webAppStatusSubscription;
}

@dynamic service;

- (instancetype) initWithLaunchSession:(LaunchSession *)launchSession service:(DeviceService *)service
{
    self = [super initWithLaunchSession:launchSession service:service];

    if (self)
    {
        _UID = 0;
        _activeCommands = [NSMutableDictionary new];

        __weak id weakSelf = self;

        _messageHandler = ^(id message)
        {
            if ([message isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *messageJSON = (NSDictionary *)message;

                NSString *contentType = [messageJSON objectForKey:@"contentType"];
                NSRange contentTypeRange = [contentType rangeOfString:@"connectsdk."];

                if (contentType && contentTypeRange.location != NSNotFound)
                {
                    NSString *payloadKey = [contentType substringFromIndex:contentTypeRange.length];

                    if (!payloadKey || payloadKey.length == 0)
                        return;

                    id payload = [messageJSON objectForKey:payloadKey];

                    if (!payload)
                        return;

                    if ([payloadKey isEqualToString:@"mediaEvent"])
                        [weakSelf handleMediaEvent:payload];
                    else if ([payloadKey isEqualToString:@"mediaCommandResponse"])
                        [weakSelf handleMediaCommandResponse:payload];
                } else
                {
                    [weakSelf handleMessage:messageJSON];
                }
            } else if ([message isKindOfClass:[NSString class]])
            {
                [weakSelf handleMessage:message];
            }
        };
    }

    return self;
}

- (int) getNextId
{
    _UID = _UID + 1;
    return _UID;
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    {
        if (subscription == _webAppStatusSubscription)
        {
            [[_webAppStatusSubscription successCalls] removeAllObjects];
            [[_webAppStatusSubscription failureCalls] removeAllObjects];
            [_webAppStatusSubscription setIsSubscribed:NO];
            _webAppStatusSubscription = nil;
        } else if (subscription == _playStateSubscription)
        {
            [[_playStateSubscription successCalls] removeAllObjects];
            [[_playStateSubscription failureCalls] removeAllObjects];
            [_playStateSubscription setIsSubscribed:NO];
            _playStateSubscription = nil;
        }
    }

    return -1;
}

#pragma mark - Message handlers

- (void) handleMediaEvent:(NSDictionary *)payload
{
    NSString *type = [payload objectForKey:@"type"];

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

- (ServiceSubscription *) subscribeWebAppStatus:(WebAppStatusBlock)success failure:(FailureBlock)failure
{
    if (!_webAppStatusSubscription)
        _webAppStatusSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_webAppStatusSubscription addSuccess:success];
    [_webAppStatusSubscription addFailure:failure];
    [_webAppStatusSubscription setIsSubscribed:YES];

    return _webAppStatusSubscription;
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher joinWebApp:self.launchSession success:success failure:failure];
}

- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service closeLaunchSession:self.launchSession success:success failure:failure];
}

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (success)
        success(self);
}

- (void) disconnectFromWebApp
{
    [self.service.mirroredService disconnectFromWebApp];
}

- (void) sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid argument"]);
    }

    NSString *commandString = [NSString stringWithFormat:@"window.connectManager.handleMessage({from: -1, message: \"%@\" })", message];

    [self.service.mirroredService.webAppWebView evaluateJavaScript:commandString completionHandler:^(NSString *result, NSError *error) {
        NSLog(@"evaluate Completed");
    }];
    if (success)
        success(nil);
}

- (void) sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid argument"]);
    }

    NSError *error;
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];

    if (error || !messageData)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not parse message into sendable format"]);
    } else
    {
        NSString *messageString = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
        NSString *commandString = [NSString stringWithFormat:@"window.connectManager.handleMessage({from: -1, message: %@ })", messageString];
        [self.service.mirroredService.webAppWebView evaluateJavaScript:commandString completionHandler:^(NSString *result, NSError *error) {
            NSLog(@"evaluate Completed");
        }];

        if (success)
            success(nil);
    }
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

-(void) displayImageWithMediaInfo:(MediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
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
        if (success){
            MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:self.launchSession andMediaControl:self.mediaControl];
            success(launchObject);
        }
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];
    
    [self sendJSON:message success:nil failure:failure];
}


-(void) playMediaWithMediaInfo:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
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
                                      @"type" : @"playMedia",
                                      @"mediaURL" : ensureString(mediaInfo.url.absoluteString),
                                      @"iconURL" : ensureString(iconURL.absoluteString),
                                      @"title" : ensureString(mediaInfo.title),
                                      @"description" : ensureString(mediaInfo.description),
                                      @"mimeType" : ensureString(mediaInfo.mimeType),
                                      @"shouldLoop" : @(shouldLoop),
                                      @"requestId" : requestId
                                      }
                              };
    
    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        if (success){
            MediaLaunchObject *launchObject = [[MediaLaunchObject alloc] initWithLaunchSession:self.launchSession andMediaControl:self.mediaControl];
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

- (void) playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"play",
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"pause",
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
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

//    if (!_connected)
//        [self connectWithSuccess:nil             failure:failure];

    if (![_playStateSubscription.successCalls containsObject:success])
        [_playStateSubscription addSuccess:success];

    if (![_playStateSubscription.failureCalls containsObject:failure])
        [_playStateSubscription addFailure:failure];

    return _playStateSubscription;
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

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
}

@end
