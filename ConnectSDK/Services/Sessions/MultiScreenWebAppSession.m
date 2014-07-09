//
// Created by Jeremy White on 6/18/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "MultiScreenWebAppSession.h"
#import "ConnectError.h"


@implementation MultiScreenWebAppSession

#pragma mark - Helper methods

- (NSString *)channelId
{
    return [NSString stringWithFormat:@"com.connectsdk.MainChannel"];
}

- (void) handleMessage:(NSNotification *)notification
{

}

- (void) handleDisconnected:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSClientMessageNotification object:_channel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSDisconnectNotification object:_channel];

    _channel = nil;
}

#pragma mark - WebAppSession methods

- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher closeWebApp:self.launchSession success:success failure:failure];
}

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.service || !self.service.device)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You can only connect to a valid WebAppSession object."]);

        return;
    }

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

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMessage:) name:MSClientMessageNotification object:self.channel];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDisconnected:) name:MSDisconnectNotification object:self.channel];

            if (success)
                success(self);
        }
    } queue:dispatch_get_main_queue()];
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connectWithSuccess:success failure:failure];
}

- (void) disconnectFromWebApp
{
    if (!self.channel)
        return;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSClientMessageNotification object:_channel];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MSDisconnectNotification object:_channel];

    [self.channel disconnectWithCompletionBlock:^{
        _channel = nil;

        if (self.delegate && [self.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
            [self.delegate webAppSessionDidDisconnect:self];
    } queue:dispatch_get_main_queue()];
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

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{

}

#pragma mark - MediaControl

@end
