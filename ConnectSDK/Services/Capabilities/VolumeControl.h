//
// Created by Jeremy White on 12/16/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "ServiceSubscription.h"

#define kVolumeControlAny @"VolumeControl.Any"

#define kVolumeControlVolumeGet @"VolumeControl.Get"
#define kVolumeControlVolumeSet @"VolumeControl.Set"
#define kVolumeControlVolumeUpDown @"VolumeControl.UpDown"
#define kVolumeControlVolumeSubscribe @"VolumeControl.Subscribe"
#define kVolumeControlMuteGet @"VolumeControl.Mute.Get"
#define kVolumeControlMuteSet @"VolumeControl.Mute.Set"
#define kVolumeControlMuteSubscribe @"VolumeControl.Mute.Subscribe"

#define kVolumeControlCapabilities @[\
    kVolumeControlVolumeGet,\
    kVolumeControlVolumeSet,\
    kVolumeControlVolumeUpDown,\
    kVolumeControlVolumeSubscribe,\
    kVolumeControlMuteGet,\
    kVolumeControlMuteSet,\
    kVolumeControlMuteSubscribe\
]

@protocol VolumeControl <NSObject>

typedef void (^ VolumeSuccessBlock)(float volume);
typedef void (^ MuteSuccessBlock)(BOOL mute);

- (id<VolumeControl>)volumeControl;
- (CapabilityPriorityLevel)volumeControlPriority;

#pragma mark Volume
- (void) volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure;
- (void) setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure;

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure;

#pragma mark Mute
- (void) getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure;
- (void) setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure;

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure;

@end
