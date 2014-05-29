//
// Created by Jeremy White on 5/28/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "AirPlayHTTPService.h"
#import "DeviceService.h"
#import "AirPlayService.h"

@interface AirPlayHTTPService () <ServiceCommandDelegate>

@end

@implementation AirPlayHTTPService

- (instancetype) initWithAirPlayService:(AirPlayService *)service
{
    self = [super init];

    if (self)
    {
        _service = service;
    }

    return self;
}

- (void) connect
{
    _connected = YES;

    if (self.service.connected && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.service.delegate deviceServiceConnectionSuccess:self.service]; });
}

- (void) disconnect
{
    _connected = NO;
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

}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{

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

}

- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{

}

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{

}

- (ServiceSubscription *) subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    return nil;
}

@end
