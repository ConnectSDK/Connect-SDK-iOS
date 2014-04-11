// Copyright 2013 Google Inc.

#import "GCKCastChannel.h"

@class GCKMediaInformation;
@class GCKMediaStatus;

@protocol GCKMediaControlChannelDelegate;

/**
 * The receiver application ID for the Default Media Receiver.
 */
extern NSString *const kGCKMediaDefaultReceiverApplicationID;

typedef NS_ENUM(NSInteger, GCKMediaControlChannelResumeState) {
  /** A resume state indicating that the player state should be left unchanged. */
  GCKMediaControlChannelResumeStateUnchanged = 0,

  /**
   * A resume state indicating that the player should be playing, regardless of its current
   * state.
   */
  GCKMediaControlChannelResumeStatePlay = 1,

  /**
   * A resume state indicating that the player should be paused, regardless of its current
   * state.
   */
  GCKMediaControlChannelResumeStatePause = 2,
};

/**
 * A CastChannel for media control operations.
 *
 * @ingroup MediaControl
 */
@interface GCKMediaControlChannel : GCKCastChannel

/**
 * The current media status, if any.
 */
@property(nonatomic, strong, readonly) GCKMediaStatus *mediaStatus;

@property(nonatomic, weak) id<GCKMediaControlChannelDelegate> delegate;

/**
 * Designated initializer.
 */
- (id)init;

/**
 * Loads, enqueues (at the end of the queue), and starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)loadMedia:(GCKMediaInformation *)mediaInfo;

/**
 * Loads, enqueues (at the end of the queue), and optionally starts playback of a new media
 * item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)loadMedia:(GCKMediaInformation *)mediaInfo autoplay:(BOOL)autoplay;

/**
 * Loads, enqueues, and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)loadMedia:(GCKMediaInformation *)mediaInfo
              autoplay:(BOOL)autoplay
          playPosition:(NSTimeInterval)playPosition;

/**
 * Loads, enqueues, and optionally starts playback of a new media item.
 *
 * @param mediaInfo An object describing the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)loadMedia:(GCKMediaInformation *)mediaInfo
              autoplay:(BOOL)autoplay
          playPosition:(NSTimeInterval)playPosition
            customData:(id)customData;

/**
 * Pauses playback of the current media item.
 *
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)pause;

/**
 * Pauses playback of the current media item.
 *
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)pauseWithCustomData:(id)customData;

/**
 * Stops playback of the current media item.
 *
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)stop;

/**
 * Stops playback of the current media item.
 *
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)stopWithCustomData:(id)customData;

/**
 * Begins (or resumes) playback of the current media item. Playback always begins at the
 * beginning of the stream. Asserts if there is no current media session.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)play;

/**
 * Begins (or resumes) playback of the current media item. Playback always begins at the
 * beginning of the stream. Asserts if there is no current media session.
 *
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)playWithCustomData:(id)customData;

/**
 * Seeks to a new time within the current media item.
 *
 * @param position The new time interval from the beginning of the stream.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)seekToTimeInterval:(NSTimeInterval)timeInterval;

/**
 * Seeks to a new position within the current media item.
 *
 * @param position The new time interval from the beginning of the stream.
 * @param resumeState The action to take after the seek operation has finished.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)seekToTimeInterval:(NSTimeInterval)position
                    resumeState:(GCKMediaControlChannelResumeState)resumeState;

/**
 * Seeks to a new position within the current media item.
 *
 * @param position The time interval from the beginning of the stream.
 * @param resumeState The action to take after the seek operation has finished.
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)seekToTimeInterval:(NSTimeInterval)position
                    resumeState:(GCKMediaControlChannelResumeState)resumeState
                     customData:(id)customData;

/**
 * Sets the stream volume. Asserts if there is no current media session.
 *
 * @param volume The new volume, in the range [0.0 - 1.0].
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)setStreamVolume:(float)volume;

/**
 * Sets the stream volume. Asserts if there is no current media session.
 *
 * @param volume The new volume, in the range [0.0 - 1.0].
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)setStreamVolume:(float)volume customData:(id)customData;

/**
 * Sets whether the stream is muted. Asserts if there is no current media session.
 *
 * @param muted Whether the stream should be muted or unmuted.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)setStreamMuted:(BOOL)muted;

/**
 * Sets whether the stream is muted. Asserts if there is no current media session.
 *
 * @param muted Whether the stream should be muted or unmuted.
 * @param customData Custom application-specific data to pass along with the request.
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)setStreamMuted:(BOOL)muted customData:(id)customData;


/**
 * Requests updated media status information from the receiver.
 * Asserts if there is no current media session.
 *
 * @return The request ID, or kGCKInvalidRequestID if the message could not be sent.
 */
- (NSInteger)requestStatus;

/**
 * Returns the approximate stream position as calculated from the last received stream
 * information and the elapsed wall-time since that update.
 */
- (NSTimeInterval)approximateStreamPosition;

@end

@protocol GCKMediaControlChannelDelegate <NSObject>

@optional

/**
 * Called when a request to load media has completed.
 *
 * @param mediaSessionId The unique media session ID that has been assigned to this media item.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    didCompleteLoadWithSessionID:(NSInteger)sessionID;

/**
 * Called when a request to load media has failed.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    didFailToLoadMediaWithError:(NSError *)error;

/**
 * Called when updated player status information is received.
 */
- (void)mediaControlChannelDidUpdateStatus:(GCKMediaControlChannel *)mediaControlChannel;

/**
 * Called when updated media metadata is received.
 */
- (void)mediaControlChannelDidUpdateMetadata:(GCKMediaControlChannel *)mediaControlChannel;

/**
 * Called when a request succeeds.
 *
 * @param requestID The request ID that failed. This is the ID returned when the request was made.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
    requestDidCompleteWithID:(NSInteger)requestID;

/**
 * Called when a request fails.
 *
 * @param requestID The request ID that failed. This is the ID returned when the request was made.
 * @param error The error. If any custom data was associated with the error, it will be in the
 * error's userInfo dictionary with the key {@code kGCKErrorCustomDataKey}.
 */
- (void)mediaControlChannel:(GCKMediaControlChannel *)mediaControlChannel
       requestDidFailWithID:(NSInteger)requestID
                      error:(NSError *)error;

@end
