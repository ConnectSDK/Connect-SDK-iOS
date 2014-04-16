//
//  TVControl.h
//  Connect SDK
//
//  Created by Jeremy White on 12/16/13.
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

/*!
 * Success block that is called upon successfully getting the current channel's information.
 *
 * @param channelInfo Object containing information about the current channel
 */
typedef void (^ CurrentChannelSuccessBlock)(ChannelInfo *channelInfo);

/*!
 * Success block that is called upon successfully getting the channel list.
 *
 * @param channelList Array containing a ChannelInfo object for each available channel on the TV
 */
typedef void (^ ChannelListSuccessBlock)(NSArray *channelList);

/*!
 * Success block that is called upon successfully getting the current program's information.
 *
 * @param programInfo Object containing information about the current program
 */
typedef void (^ ProgramInfoSuccessBlock)(ProgramInfo *programInfo);

/*!
 * Success block that is called upon successfully getting the program list for the current channel.
 *
 * @param programList Array containing a ProgramInfo object for each available program on the TV's current channel
 */
typedef void (^ ProgramListSuccessBlock)(NSArray *programList);

/*!
 * Success block that is called upon successfully getting the TV's 3D mode
 *
 * @param tv3DEnabled Whether 3D mode is currently enabled on the TV
 */
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
