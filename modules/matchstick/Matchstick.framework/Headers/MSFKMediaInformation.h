//
// Created by Jiang Lu on 14-4-1.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

@class MSFKMediaMetadata;

typedef NS_ENUM(NSInteger, MSFKMediaStreamType) {
    /** A stream type of "none". */
            MSFKMediaStreamTypeNone = 0,
    /** A buffered stream type. */
            MSFKMediaStreamTypeBuffered = 1,
    /** A live stream type. */
            MSFKMediaStreamTypeLive = 2,
    /** An unknown stream type. */
            MSFKMediaStreamTypeUnknown = 99,
};

/**
 * A class that aggregates information about a media item.
 */
@interface MSFKMediaInformation : NSObject

/**
 * The stream type.
 */
@property(nonatomic) MSFKMediaStreamType streamType;

/**
 * The content (MIME) type.
 */
@property(nonatomic, copy) NSString *contentType;

/**
 * The media item metadata.
 */
@property(nonatomic, strong) MSFKMediaMetadata *metadata;

/**
 * The length of time for the stream, in seconds.
 */
@property(nonatomic) NSTimeInterval streamDuration;

/**
 * The custom data, if any.
 */
@property(nonatomic, strong) id customData;

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
             streamType:(MSFKMediaStreamType)streamType
            contentType:(NSString *)contentType
               metadata:(MSFKMediaMetadata *)metadata
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
