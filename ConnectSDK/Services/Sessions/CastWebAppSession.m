//
// Created by Jeremy White on 2/23/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "CastWebAppSession.h"
#import "ConnectError.h"


@interface CastWebAppSession () <GCKMediaControlChannelDelegate>
{
    MediaPlayStateSuccessBlock _immediatePlayStateCallback;

    ServiceSubscription *_playStateSubscription;
}

@end

@implementation CastWebAppSession

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_castServiceChannel)
        [self disconnectFromWebApp];
    
    FailureBlock channelFailure = ^(NSError *error) {
        _castServiceChannel = nil;
        
        if (failure)
            failure(error);
    };
    
    _castServiceChannel = [[CastServiceChannel alloc] initWithAppId:self.launchSession.appId session:self];
    _castServiceChannel.connectionSuccess = success;
    _castServiceChannel.connectionFailure = channelFailure;

    [self.service.castDeviceManager addChannel:_castServiceChannel];
}

- (void)disconnectFromWebApp
{
    if (!_castServiceChannel)
        return;

    [self.service.castDeviceManager removeChannel:_castServiceChannel];
    _castServiceChannel = nil;
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

    if (_castServiceChannel == nil)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Cannot send a message to the web app without first connecting"]);

        return;
    }

    BOOL messageSent = [_castServiceChannel sendTextMessage:message];

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

#pragma mark - GCKMediaControlChannelDelegate methods

- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel
{
    [self.service mediaControlChannelDidUpdateStatus:mediaControlChannel];

    MediaControlPlayState playState;

    switch (mediaControlChannel.mediaStatus.playerState)
    {
        case GCKMediaPlayerStateIdle:
            if (mediaControlChannel.mediaStatus.idleReason == GCKMediaPlayerIdleReasonFinished)
                playState = MediaControlPlayStateFinished;
            else
                playState = MediaControlPlayStateIdle;
            break;

        case GCKMediaPlayerStatePlaying:
            playState = MediaControlPlayStatePlaying;
            break;

        case GCKMediaPlayerStatePaused:
            playState = MediaControlPlayStatePaused;
            break;

        case GCKMediaPlayerStateBuffering:
            playState = MediaControlPlayStateBuffering;
            break;

        case GCKMediaPlayerStateUnknown:
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
    if (self.service.castMediaControlChannel.mediaStatus)
    {
        if (success)
            success(self.service.castMediaControlChannel.mediaStatus.mediaInformation.streamDuration);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.service.castMediaControlChannel.mediaStatus)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    NSInteger result = [self.service.castMediaControlChannel seekToTimeInterval:position];

    if (result == kGCKInvalidRequestID)
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
    if (!self.service.castMediaControlChannel.mediaStatus)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);

        return;
    }

    _immediatePlayStateCallback = success;

    NSInteger result = [self.service.castMediaControlChannel requestStatus];

    if (result == kGCKInvalidRequestID)
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

    [self.service.castMediaControlChannel requestStatus];

    return _playStateSubscription;
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.service.castMediaControlChannel.mediaStatus)
    {
        if (success)
            success(self.service.castMediaControlChannel.approximateStreamPosition);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"There is no media currently available"]);
    }
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_castServiceChannel)
        [self disconnectFromWebApp];

    [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
}

@end
