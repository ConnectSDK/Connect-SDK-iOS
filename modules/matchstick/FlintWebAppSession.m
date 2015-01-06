

//
//  CastWebAppSession.m
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

#import "FlintWebAppSession.h"
#import "ConnectError.h"

@interface FlintWebAppSession () <MSFKMediaControlChannelDelegate>
{
    MediaPlayStateSuccessBlock _immediatePlayStateCallback;

    ServiceSubscription *_playStateSubscription;
}

@end

@implementation FlintWebAppSession

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_flintServiceChannel)
        [self disconnectFromWebApp];
    
    FailureBlock channelFailure = ^(NSError *error) {
        _flintServiceChannel = nil;
        
        if (failure)
            failure(error);
    };
    
    _flintServiceChannel = [[FlintServiceChannel alloc] initWithAppId:self.launchSession.appId session:self];

    // clean up old instance of channel, if it exists
    [self.service.flintDeviceManager removeChannel:_flintServiceChannel];

    _flintServiceChannel.connectionSuccess = success;
    _flintServiceChannel.connectionFailure = channelFailure;

    [self.service.flintDeviceManager addChannel:_flintServiceChannel];
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connectWithSuccess:success failure:failure];
}

- (void)disconnectFromWebApp
{
    if (!_flintServiceChannel)
        return;

    [self.service.flintDeviceManager removeChannel:_flintServiceChannel];
    _flintServiceChannel = nil;
}

- (void) _handleAppClose
{
    if (_playStateSubscription)
    {
        [_playStateSubscription.successCalls enumerateObjectsUsingBlock:^(MediaPlayStateSuccessBlock success, NSUInteger idx, BOOL *stop) {
            success(MediaControlPlayStateIdle);
        }];
    }

    if (self.delegate)
        [self.delegate webAppSessionDidDisconnect:self];
}

#pragma mark - ServiceCommandDelegate

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    {
        if (subscription == _playStateSubscription)
            _playStateSubscription = nil;
    }

    return -1;
}

#pragma mark - App to app

- (void)sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (message == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send nil message."]);

        return;
    }

    if (_flintServiceChannel == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Cannot send a message to the web app without first connecting"]);

        return;
    }

    BOOL messageSent = [_flintServiceChannel sendTextMessage:message];

    if (messageSent)
    {
        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Message could not be sent at this time."]);
    }
}

- (void)sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (message == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot send nil message."]);

        return;
    }

    NSError *error;
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:message options:0 error:&error];

    if (error || messageData == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Failed to parse message dictionary into a JSON object."]);

        return;
    } else
    {
        NSString *messageJSON = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];

        [self sendText:messageJSON success:success failure:failure];
    }
}

#pragma mark - MSFKMediaControlChannelDelegate methods

-(void)mediaControlChannel:(MSFKMediaControlChannel *)mediaControlChannel didCompleteLoadWithSessionID:(NSInteger)sessionID
{
    NSLog(@"---mediaControlChannel");
}

- (void)mediaControlChannelDidUpdateStatus:(MSFKMediaControlChannel *)mediaControlChannel
{
    MediaControlPlayState playState;

    switch (mediaControlChannel.mediaStatus.playerState)
    {
        case MSFKMediaPlayerStateIdle:
            if (mediaControlChannel.mediaStatus.idleReason == MSFKMediaPlayerIdleReasonFinished)
                playState = MediaControlPlayStateFinished;
            else
                playState = MediaControlPlayStateIdle;
            break;

        case MSFKMediaPlayerStatePlaying:
            playState = MediaControlPlayStatePlaying;
            break;

        case MSFKMediaPlayerStatePaused:
            playState = MediaControlPlayStatePaused;
            break;

        case MSFKMediaPlayerStateBuffering:
            playState = MediaControlPlayStateBuffering;
            break;

        case MSFKMediaPlayerStateUnknown:
        default:
            playState = MediaControlPlayStateUnknown;
    }

    if (_immediatePlayStateCallback)
    {
        _immediatePlayStateCallback(playState);
        _immediatePlayStateCallback = nil;
    }

    if (_playStateSubscription)
    {
        [_playStateSubscription.successCalls enumerateObjectsUsingBlock:^(id success, NSUInteger idx, BOOL *stop)
        {
            MediaPlayStateSuccessBlock mediaPlayStateSuccess = (MediaPlayStateSuccessBlock) success;

            if (mediaPlayStateSuccess)
                mediaPlayStateSuccess(playState);
        }];
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

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:nil]);
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    MSFKMediaMetadata *metaData = [[MSFKMediaMetadata alloc] initWithMetadataType:MSFKMediaMetadataTypeMovie];
    [metaData setString:title forKey:kMSFKMetadataKeyTitle];
    [metaData setString:description forKey:kMSFKMetadataKeySubtitle];

    if (iconURL)
    {
        MSFKImage *iconImage = [[MSFKImage alloc] initWithURL:iconURL width:100 height:100];
        [metaData addImage:iconImage];
    }

    MSFKMediaInformation *mediaInformation = [[MSFKMediaInformation alloc] initWithContentID:mediaURL.absoluteString streamType:MSFKMediaStreamTypeBuffered contentType:mimeType metadata:metaData streamDuration:1000 customData:nil];

    [self.service playMedia:mediaInformation webAppId:self.launchSession.appId success:^(LaunchSession *launchSession, id <MediaControl> mediaControl)
    {
        self.launchSession.sessionId = launchSession.sessionId;

        if (success)
            success(self.launchSession, self.mediaControl);
    } failure:failure];
}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self closeWithSuccess:success failure:failure];
}

#pragma mark - Media Control

- (id <MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.service.flintMediaControlChannel.mediaStatus)
    {
        if (success)
            success(self.service.flintMediaControlChannel.mediaStatus.mediaInformation.streamDuration);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.service.flintMediaControlChannel.mediaStatus)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    NSInteger result = [self.service.flintMediaControlChannel seekToTimeInterval:position];

    if (result == kMSFKInvalidRequestID)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    } else
    {
        if (success)
            success(nil);
    }
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.service.flintMediaControlChannel.mediaStatus)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    _immediatePlayStateCallback = success;

    NSInteger result = [self.service.flintMediaControlChannel requestStatus];

    if (result == kMSFKInvalidRequestID)
    {
        _immediatePlayStateCallback = nil;

        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    }
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (!_playStateSubscription)
        _playStateSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_playStateSubscription addSuccess:success];
    [_playStateSubscription addFailure:failure];

    [self.service.flintMediaControlChannel requestStatus];

    return _playStateSubscription;
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.service.flintMediaControlChannel.mediaStatus)
    {
        if (success)
            success(self.service.flintMediaControlChannel.approximateStreamPosition);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_flintServiceChannel)
        [self disconnectFromWebApp];

    [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
}

@end
