//
// Created by Jiang Lu on 14-4-1.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>

@class MSFKMediaInformation;

/** A flag (bitmask) indicating that a media item can be paused. */
extern const NSInteger kMSFKMediaCommandPause;

/** A flag (bitmask) indicating that a media item supports seeking. */
extern const NSInteger kMSFKMediaCommandSeek;

/** A flag (bitmask) indicating that a media item's audio volume can be changed. */
extern const NSInteger kMSFKMediaCommandSetVolume;

/** A flag (bitmask) indicating that a media item's audio can be muted. */
extern const NSInteger kMSFKMediaCommandToggleMute;

/** A flag (bitmask) indicating that a media item supports skipping forward. */
extern const NSInteger kMSFKMediaCommandSkipForward;

/** A flag (bitmask) indicating that a media item supports skipping bMSFKward. */
extern const NSInteger kMSFKMediaCommandSkipBackward;

typedef NS_ENUM(NSInteger, MSFKMediaPlayerState) {
    /** Constant indicating unknown player state. */
    MSFKMediaPlayerStateUnknown = 0,
    /** Constant indicating that the media player is idle. */
    MSFKMediaPlayerStateIdle = 1,
    /** Constant indicating that the media player is playing. */
    MSFKMediaPlayerStatePlaying = 2,
    /** Constant indicating that the media player is paused. */
    MSFKMediaPlayerStatePaused = 3,
    /** Constant indicating that the media player is buffering. */
    MSFKMediaPlayerStateBuffering = 4,
};

typedef NS_ENUM(NSInteger, MSFKMediaPlayerIdleReason) {
    /** Constant indicating that the player currently has no idle reason. */
    MSFKMediaPlayerIdleReasonNone = 0,
    
    /** Constant indicating that the player is idle because playback has finished. */
    MSFKMediaPlayerIdleReasonFinished = 1,
    
    /**
     * Constant indicating that the player is idle because playback has been cancelled in
     * response to a STOP command.
     */
    MSFKMediaPlayerIdleReasonCancelled = 2,
    
    /**
     * Constant indicating that the player is idle because playback has been interrupted by
     * a LOAD command.
     */
    MSFKMediaPlayerIdleReasonInterrupted = 3,
    
    /** Constant indicating that the player is idle because a playback error has occurred. */
    MSFKMediaPlayerIdleReasonError = 4,
};

/**
 * A class that holds status information about some media.
 */
@interface MSFKMediaStatus : NSObject

/**
 * The media session ID for this item.
 */
@property(nonatomic,readonly) NSInteger mediaSessionID;

/**
 * The current player state.
 */
@property(nonatomic,readonly) MSFKMediaPlayerState playerState;

/**
 * The current idle reason. This value is only meaningful if the player state is
 * MSFKMediaPlayerStateIdle.
 */
@property(nonatomic,readonly) MSFKMediaPlayerIdleReason idleReason;

/**
 * Gets the current stream playback rate. This will be negative if the stream is seeking
 * backwards, 0 if the stream is paused, 1 if the stream is playing normally, and some other
 * postive value if the stream is seeking forwards.
 */
@property(nonatomic,readonly) float playbackRate;

/**
 * The MSFKMediaInformation for this item.
 */
@property(nonatomic, strong, readonly) MSFKMediaInformation *mediaInformation;

/**
 * The current stream position, as an NSTimeInterval from the start of the stream.
 */
@property(nonatomic) NSTimeInterval streamPosition;

/**
 * The stream's volume.
 */
@property(nonatomic) float volume;

/**
 * The stream's mute state.
 */
@property(nonatomic,readonly) BOOL isMuted;

/**
 * Any custom data that is associated with the media item.
 */
@property(nonatomic, strong ,readonly) id customData;

/**
 * Designated initializer.
 *
 * @param mediaSessionID The media session ID.
 * @param mediaInformation The media information.
 */
- (id)initWithSessionID:(NSInteger)mediaSessionID
       mediaInformation:(MSFKMediaInformation *)mediaInformation;

/**
 * Checks if the stream supports a given control command.
 */
- (BOOL)isMediaCommandSupported:(NSInteger)command;

@end