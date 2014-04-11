// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>

@class GCKSenderApplicationInfo;

/**
 * Information about a first-screen application.
 *
 * @ingroup Applications
 */
@interface GCKApplicationMetadata : NSObject

/** The application's ID. */
@property(nonatomic, copy, readonly) NSString *applicationID;

/** The application's name. */
@property(nonatomic, copy, readonly) NSString *applicationName;

/** The application GCKImage images. */
@property(nonatomic, copy, readonly) NSArray *images;

/**
 * The set of namespaces supported by this application.
 */
@property(nonatomic, copy, readonly) NSArray *namespaces;

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
- (GCKSenderApplicationInfo *)senderApplicationInfo;

@end
