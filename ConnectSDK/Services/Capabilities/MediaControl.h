//
// Created by Jeremy White on 1/22/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "ServiceSubscription.h"

#define kMediaControlAny @"MediaControl.Any"

#define kMediaControlPlay @"MediaControl.Play"
#define kMediaControlPause @"MediaControl.Pause"
#define kMediaControlStop @"MediaControl.Stop"
#define kMediaControlDuration @"MediaControl.Duration"
#define kMediaControlRewind @"MediaControl.Rewind"
#define kMediaControlFastForward @"MediaControl.FastForward"
#define kMediaControlSeek @"MediaControl.Seek"
#define kMediaControlPlayState @"MediaControl.PlayState"
#define kMediaControlPlayStateSubscribe @"MediaControl.PlayState.Subscribe"
#define kMediaControlPosition @"MediaControl.Position"

#define kMediaControlCapabilities @[\
    kMediaControlPlay,\
    kMediaControlPause,\
    kMediaControlStop,\
    kMediaControlDuration,\
    kMediaControlRewind,\
    kMediaControlFastForward,\
    kMediaControlSeek,\
    kMediaControlPlayState,\
    kMediaControlPlayStateSubscribe,\
    kMediaControlPosition\
]

typedef enum {
    MediaControlPlayStateUnknown,
    MediaControlPlayStateIdle,
    MediaControlPlayStatePlaying,
    MediaControlPlayStatePaused,
    MediaControlPlayStateBuffering,
    MediaControlPlayStateFinished
} MediaControlPlayState;

@protocol MediaControl <NSObject>

typedef void (^ MediaPlayStateSuccessBlock)(MediaControlPlayState playState);
typedef void (^ MediaPositionSuccessBlock)(NSTimeInterval position);
typedef void (^ MediaDurationSuccessBlock)(NSTimeInterval duration);

- (id<MediaControl>) mediaControl;
- (CapabilityPriorityLevel) mediaControlPriority;

#pragma mark Play control
- (void) playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@optional
- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure;

#pragma mark Play info
- (void) getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure;
- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure;

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure;

@end
