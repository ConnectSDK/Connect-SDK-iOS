//
// Created by Jeremy White on 6/18/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "MultiScreenWebAppSession.h"
#import "ConnectError.h"

#define kCTMultiScreenConnectTimeout 3

@implementation MultiScreenWebAppSession
{
    ServiceSubscription *_playStateSubscription;
    NSMutableDictionary *_activeCommands;

    int _UID;
}

#pragma mark - Helper methods

- (NSString *)channelId
{
    return [NSString stringWithFormat:@"com.connectsdk.MainChannel"];
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

- (int) getNextId
{
    _UID = _UID + 1;
    return _UID;
}

#pragma mark - Message handlers

- (void) handleMessageNotification:(NSNotification *)notification
{
    NSDictionary *payload = notification.userInfo;
    NSString *message = payload[@"message"];

    NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *messageJSON = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];

    if (messageJSON && !error)
    {
        NSString *contentType = [messageJSON objectForKey:@"contentType"];
        NSRange contentTypeRange = [contentType rangeOfString:@"connectsdk."];

        if (contentType && contentTypeRange.location != NSNotFound)
        {
            NSString *payloadKey = [contentType substringFromIndex:contentTypeRange.length];

            if (!payloadKey || payloadKey.length == 0)
                return;

            id messagePayload = [messageJSON objectForKey:payloadKey];

            if (!messagePayload)
                return;

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
}

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

- (void) handleDisconnected:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSClientMessageNotification object:_channel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSDisconnectNotification object:_channel];

    _channel = nil;
}

#pragma mark - WebAppSession methods

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.service || !self.service.device)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You can only connect to a valid WebAppSession object."]);

        return;
    }

    _activeCommands = [NSMutableDictionary new];
    _UID = 0;

    [self.service.device connectToChannel:self.channelId completionBlock:^(MSChannel *channel, NSError *error) {
        if (error || !channel)
        {
            if (!error)
                error = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Unknown error connecting to web app"];

            if (failure)
                failure(error);
        } else
        {
            _channel = channel;

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMessageNotification:) name:MSClientMessageNotification object:_channel];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnected:) name:MSDisconnectNotification object:_channel];

            if (success)
                success(self);
        }
    } queue:dispatch_get_main_queue()];
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.application updateStatusWithCompletionBlock:^(MS_APPLICATION_STATUS status, NSError *error) {
        if (status == MS_APP_RUNNING)
        {
            [self connectWithSuccess:success failure:failure];
        } else
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Cannot join a web app that is not running"]);
        }
    } queue:dispatch_get_main_queue()];
}

- (void)sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message || message.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send an empty message"]);

        return;
    }

    if (self.channel && self.channel.isConnected)
    {
        [self.channel sendToHost:message];

        if (success)
            dispatch_on_main(^{ success(nil); });
    } else
    {
        if (failure)
            dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Connection has not been established or has been lost"]); });
    }
}

- (void)sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message || message.count == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send an empty message"]);

        return;
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];

    if (error || !jsonData)
    {
        if (!error)
            error = [ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid JSON object"];

        if (failure)
            dispatch_on_main(^{ failure(error); });
    } else
    {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

        [self sendText:jsonString success:success failure:failure];
    }
}

- (void) disconnectFromWebApp
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSClientMessageNotification object:_channel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSDisconnectNotification object:_channel];

    if (!self.channel)
        return;

    [self.channel disconnectWithCompletionBlock:^{
        _channel = nil;

        if (self.delegate && [self.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
            [self.delegate webAppSessionDidDisconnect:self];
    } queue:dispatch_get_main_queue()];
}

- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.channel && self.channel.isConnected)
    {
        // This is a hack to enable closing of bridged web apps that we didn't open
        NSDictionary *closeCommand = @{
                @"contentType" : @"connectsdk.serviceCommand",
                @"serviceCommand" : @{
                        @"type" : @"close"
                }
        };

        [self sendJSON:closeCommand success:^(id responseObject)
                {
                    [self disconnectFromWebApp];

                    if (success)
                        success(responseObject);
                } failure:^(NSError *closeError)
                {
                    [self disconnectFromWebApp];

                    if (failure)
                        failure(closeError);
                }];
    } else
    {
        [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
    }
}

#pragma mark - MediaPlayer

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
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"displayImage",
                    @"mediaURL" : ensureString(imageURL.absoluteString),
                    @"iconURL" : ensureString(iconURL.absoluteString),
                    @"title" : ensureString(title),
                    @"description" : ensureString(description),
                    @"mimeType" : ensureString(mimeType),
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        if (success)
            success(self.launchSession, self.mediaControl);
    };
    command.callbackError = failure;
    [_activeCommands setObject:command forKey:requestId];

    [self sendJSON:message success:nil failure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    int requestIdNumber = [self getNextId];
    NSString *requestId = [NSString stringWithFormat:@"req%d", requestIdNumber];

    NSDictionary *message = @{
            @"contentType" : @"connectsdk.mediaCommand",
            @"mediaCommand" : @{
                    @"type" : @"playMedia",
                    @"mediaURL" : ensureString(mediaURL.absoluteString),
                    @"iconURL" : ensureString(iconURL.absoluteString),
                    @"title" : ensureString(title),
                    @"description" : ensureString(description),
                    @"mimeType" : ensureString(mimeType),
                    @"shouldLoop" : @(shouldLoop),
                    @"requestId" : requestId
            }
    };

    ServiceCommand *command = [ServiceCommand commandWithDelegate:nil target:nil payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        if (success)
            success(self.launchSession, self.mediaControl);
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

    if (!self.channel || !self.channel.isConnected)
        [self connectWithSuccess:nil failure:failure];

    if (![_playStateSubscription.successCalls containsObject:success])
        [_playStateSubscription addSuccess:success];

    if (![_playStateSubscription.failureCalls containsObject:failure])
        [_playStateSubscription addFailure:failure];

    return _playStateSubscription;
}

@end
