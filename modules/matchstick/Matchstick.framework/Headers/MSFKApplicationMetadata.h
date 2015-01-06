//
// Created by Jiang Lu on 14-4-8.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>

@class MSFKSenderApplicationInfo;

/**
 * Information about a first-screen application.
 *
 * @ingroup Applications
 */
@interface MSFKApplicationMetadata : NSObject

@property(nonatomic,copy,readonly) NSDictionary *additionalData;

/** The application's id. */
@property(nonatomic, copy, readonly) NSString *applicationID;

/** The application's URL. */
@property(nonatomic, copy, readonly) NSString *applicationURL;

/** The session's ID. */
@property(nonatomic, copy, readonly) NSString *sessionID;

/** The application's name. */
@property(nonatomic, copy, readonly) NSString *applicationName;

/** The application MSFKImage images. */
@property(nonatomic, copy, readonly) NSArray *images;

/**
 * The set of namespaces supported by this application.
 */
@property(nonatomic, copy, readonly) NSArray *namespaces;

@property(nonatomic, copy, readonly) NSString *transportID;

- (id)initWithJSONObject:(id)jsonObject;

/**
 * The identifier of the sender application that is the counterpart to the receiver
 * application, if any.
 */
- (NSString *)senderAppIdentifier;

/**
 * The launch URL for the sender application that is the counterpart to the receiver
 * application, if any.
 */
- (NSURL *)senderAppLaunchURL;

/**
 * Returns the sender application info for this platform, or nil if there isn't one.
 */
- (MSFKSenderApplicationInfo *)senderApplicationInfo;

@end