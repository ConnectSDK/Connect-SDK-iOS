//
// Created by Jiang Lu on 14-4-7.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MSFKSenderApplicationInfoPlatform) {
    MSFKSenderApplicationInfoPlatformAndroid = 1,
    MSFKSenderApplicationInfoPlatformiOS = 2,
    MSFKSenderApplicationInfoPlatformChrome = 3,
};

/**
 * Container class for information about a sender application.
 */
@interface MSFKSenderApplicationInfo : NSObject<NSCopying>

/** The sender app's platform. */
@property(nonatomic, readonly) MSFKSenderApplicationInfoPlatform platform;

/** The sender app's unique identifier. */
@property(nonatomic, copy, readonly) NSString *appIdentifier;

/** The sender app's launch URL. */
@property(nonatomic, strong, readonly) NSURL *launchURL;

/** @cond INTERNAL */

/**
 * Designated initializer. Constructs a new SenderApplicationInfo object.
 *
 * @param platform The sender platform.
 * @param appIdentifier The sender application's unique identifer.
 * @param launchUrl The URL for launching the application on the sender platform.
 */
- (id)initWithPlatform:(MSFKSenderApplicationInfoPlatform)platform
         appIdentifier:(NSString *)appIdentifier
             launchURL:(NSURL *)launchURL;

/**
 * Constructs a new SenderApplicationInfo object from JSON data.
 *
 * @param JSONObject The JSON data.
 */
- (id)initWithJSONObject:(id)JSONObject;

/** @endcond */

@end
