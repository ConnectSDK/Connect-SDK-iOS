// Copyright 2013 Google Inc.

@class GCKMediaMetadata;

typedef NS_ENUM(NSInteger, GCKMediaStreamType) {
  /** A stream type of "none". */
  GCKMediaStreamTypeNone = 0,
  /** A buffered stream type. */
  GCKMediaStreamTypeBuffered = 1,
  /** A live stream type. */
  GCKMediaStreamTypeLive = 2,
  /** An unknown stream type. */
  GCKMediaStreamTypeUnknown = 99,
};

/**
 * A class that aggregates information about a media item.
 */
@interface GCKMediaInformation : NSObject

/**
 * The stream type.
 */
@property(nonatomic, readonly) GCKMediaStreamType streamType;

/**
 * The content (MIME) type.
 */
@property(nonatomic, copy, readonly) NSString *contentType;

/**
 * The media item metadata.
 */
@property(nonatomic, strong, readonly) GCKMediaMetadata *metadata;

/**
 * The length of time for the stream, in seconds.
 */
@property(nonatomic, readonly) NSTimeInterval streamDuration;

/**
 * The custom data, if any.
 */
@property(nonatomic, strong, readonly) id customData;

/**
 * Designated initializer.
 *
 * @param contentID The content ID.
 * @param streamType The stream type.
 * @param contentType The content (MIME) type.
 * @param metadata The media item metadata.
 * @param streamDuration The stream duration.
 * @param customData The custom application-specific data.
 */
- (id)initWithContentID:(NSString *)contentID
             streamType:(GCKMediaStreamType)streamType
            contentType:(NSString *)contentType
               metadata:(GCKMediaMetadata *)metadata
         streamDuration:(NSTimeInterval)streamDuration
             customData:(id)customData;

/** @cond INTERNAL */

- (id)initWithJSONObject:(id)JSONObject;

/**
 * Create a JSON object which can serialized with NSJSONSerialization to pass to the receiver.
 */
- (id)JSONObject;

/** @endcond */

@end
