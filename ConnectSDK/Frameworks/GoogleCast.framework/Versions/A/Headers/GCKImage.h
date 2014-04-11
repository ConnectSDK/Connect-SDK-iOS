// Copyright 2013 Google Inc.

/**
 * A class that represents an image that is located on a web server.
 */
@interface GCKImage : NSObject <NSCopying, NSCoding>

/**
 * The image URL.
 */
@property(nonatomic, readonly, strong) NSURL *URL;

/**
 * The image width, in pixels.
 */
@property(nonatomic, readonly) NSInteger width;

/**
 * The image height, in pixels.
 */
@property(nonatomic, readonly) NSInteger height;

/**
 * Constructs a new {@link MediaImage} with the given URL and dimensions. Designated initializer.
 * Asserts that the URL is not be null or empty, and the dimensions are not invalid.
 *
 * @param url The URL of the image.
 * @param width The width of the image, in pixels.
 * @param height The height of the image, in pixels.
 */
- (id)initWithURL:(NSURL *)URL width:(NSInteger)width height:(NSInteger)height;

/** @cond INTERNAL */

/**
 * Initalizes this GCKImage from its JSON representation.
 */
- (id)initWithJSONObject:(id)JSONObject;

/**
 * Create a JSON object which can serialized with NSJSONSerialization to pass to the receiver.
 */
- (id)JSONObject;

/** @endcond */

@end
