//
//  MediaControl.h
//  Connect SDK
//
//  Created by Jeremy White on 1/22/14.
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
#define kMediaControlMetadata @"MediaControl.MetaData"
#define kMediaControlMetadataSubscribe @"MediaControl.MetaData.Subscribe"

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
    kMediaControlPosition,\
    kMediaControlMetadata,\
    kMediaControlMetadataSubscribe\
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

/*!
 * Success block that is called upon any change in a media file's play state.
 *
 * @param playState Play state of the current media file
 */
typedef void (^ MediaPlayStateSuccessBlock)(MediaControlPlayState playState);

/*!
 * Success block that is called upon successfully getting the media file's current playhead position.
 *
 * @param position Current playhead position of the current media file, in seconds
 */
typedef void (^ MediaPositionSuccessBlock)(NSTimeInterval position);

/*!
 * Success block that is called upon successfully getting the media file's duration.
 *
 * @param duration Duration of the current media file, in seconds
 */
typedef void (^ MediaDurationSuccessBlock)(NSTimeInterval duration);

- (id<MediaControl>) mediaControl;
- (CapabilityPriorityLevel) mediaControlPriority;

#pragma mark Play control
- (void) playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure;

#pragma mark Play info
- (void) getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure;
- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure;
- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@end
