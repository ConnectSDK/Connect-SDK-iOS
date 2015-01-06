//
// Created by Jiang Lu on 14-4-8.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>

/**
 * A class that represents an image that is located on a web server.
 */
@interface MSFKImage : NSObject

/**
 * The image URL.
 */
@property(nonatomic, strong) NSURL *URL;

/**
 * The image width, in pixels.
 */
@property(nonatomic) NSInteger width;

/**
 * The image height, in pixels.
 */
@property(nonatomic) NSInteger height;

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
 * Initalizes this MSFKImage from its JSON representation.
 */
- (id)initWithJSONObject:(id)jsonObject;

/**
 * Create a JSON object which can serialized with NSJSONSerialization to pass to the receiver.
 */
- (id)JSONObject;

/** @endcond */

@end