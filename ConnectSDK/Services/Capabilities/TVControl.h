//
// Created by Jeremy White on 12/16/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "ChannelInfo.h"
#import "ProgramInfo.h"
#import "ServiceSubscription.h"

#define kTVControlAny @"TVControl.Any"

#define kTVControlChannelGet @"TVControl.Channel.Get"
#define kTVControlChannelSet @"TVControl.Channel.Set"
#define kTVControlChannelUp @"TVControl.Channel.Up"
#define kTVControlChannelDown @"TVControl.Channel.Down"
#define kTVControlChannelList @"TVControl.Channel.List"
#define kTVControlChannelSubscribe @"TVControl.Channel.Subscribe"
#define kTVControlProgramGet @"TVControl.Program.Get"
#define kTVControlProgramList @"TVControl.Program.List"
#define kTVControlProgramSubscribe @"TVControl.Program.Subscribe"
#define kTVControlProgramListSubscribe @"TVControl.Program.List.Subscribe"
#define kTVControl3DGet @"TVControl.3D.Get"
#define kTVControl3DSet @"TVControl.3D.Set"
#define kTVControl3DSubscribe @"TVControl.3D.Subscribe"

#define kTVControlCapabilities @[\
    kTVControlChannelGet,\
    kTVControlChannelSet,\
    kTVControlChannelUp,\
    kTVControlChannelDown,\
    kTVControlChannelList,\
    kTVControlChannelSubscribe,\
    kTVControlProgramGet,\
    kTVControlProgramList,\
    kTVControlProgramSubscribe,\
    kTVControlProgramListSubscribe,\
    kTVControl3DGet,\
    kTVControl3DSet,\
    kTVControl3DSubscribe\
]

@protocol TVControl <NSObject>

typedef void (^ CurrentChannelSuccessBlock)(ChannelInfo *channelInfo);
typedef void (^ ChannelListSuccessBlock)(NSArray *channelList);
typedef void (^ ProgramInfoSuccessBlock)(ProgramInfo *programInfo);
typedef void (^ ProgramListSuccessBlock)(NSArray *programList);
typedef void (^ TV3DEnabledSuccessBlock)(BOOL tv3DEnabled);

- (id<TVControl>)tvControl;
- (CapabilityPriorityLevel)tvControlPriority;

#pragma mark Set channel
- (void) channelUpWithSuccess:(SuccessBlock)success failure:(FailureBlock) failure;
- (void) channelDownWithSuccess:(SuccessBlock)success failure:(FailureBlock) failure;
- (void) setChannel:(ChannelInfo *)channelInfo success:(SuccessBlock)success failure:(FailureBlock) failure;

#pragma mark Channel Info
- (void) getCurrentChannelWithSuccess:(CurrentChannelSuccessBlock)success failure:(FailureBlock) failure;
- (ServiceSubscription *)subscribeCurrentChannelWithSuccess:(CurrentChannelSuccessBlock)success failure:(FailureBlock) failure;
- (void) getChannelListWithSuccess:(ChannelListSuccessBlock)success failure:(FailureBlock) failure;

#pragma mark Program Info
- (void) getProgramInfoWithSuccess:(ProgramInfoSuccessBlock)success failure:(FailureBlock) failure;
- (ServiceSubscription *)subscribeProgramInfoWithSuccess:(ProgramInfoSuccessBlock)success failure:(FailureBlock) failure;

- (void) getProgramListWithSuccess:(ProgramListSuccessBlock)success failure:(FailureBlock) failure;
- (ServiceSubscription *)subscribeProgramListWithSuccess:(ProgramListSuccessBlock)success failure:(FailureBlock) failure;

#pragma mark 3D mode
- (void) get3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock) failure;
- (void) set3DEnabled:(BOOL)enabled success:(SuccessBlock)success failure:(FailureBlock) failure;
- (ServiceSubscription *) subscribe3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock) failure;

@end
