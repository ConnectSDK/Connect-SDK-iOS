//
// Created by Jeremy White on 2/21/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "WebAppSession.h"
#import "ConnectError.h"


@implementation WebAppSession

- (instancetype) initWithJSONObject:(NSDictionary*)dict
{
    return nil; // not supported
}

- (NSDictionary*) toJSONObject
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    if (self.launchSession) {
        dict[@"launchSession"] = [self.launchSession toJSONObject];
    }
    
    if (self.service && self.service.serviceDescription) {
        dict[@"serviceName"] = [self.service serviceName];
    }
    
    return dict;
}

- (id)initWithLaunchSession:(LaunchSession *)launchSession service:(DeviceService *)service
{
    self = [super init];

    if (self)
    {
        _launchSession = launchSession;
        _service = service;
    }

    return self;
}

- (void) sendNotSupportedFailure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - ServiceCommandDelegate methods

- (int)sendCommand:(ServiceCommand *)comm withPayload:(id)payload toURL:(NSURL *)URL
{
    return -1;
}

- (int)sendAsync:(ServiceAsyncCommand *)async withPayload:(id)payload toURL:(NSURL *)URL
{
    return -1;
}

- (int)sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    return -1;
}

#pragma mark - Web App methods

- (ServiceSubscription *) subscribeWebAppStatus:(WebAppStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];

    return nil;
}

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)disconnectFromWebApp { }

- (void)sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

#pragma mark - MediaControl
#pragma mark MediaControl required methods

- (id <MediaControl>)mediaControl
{
    return nil;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelVeryLow;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<MediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl playWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<MediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl pauseWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<MediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl stopWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<MediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl rewindWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<MediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl fastForwardWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

#pragma mark MediaControl optional methods

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];

    return nil;
}

- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

@end
