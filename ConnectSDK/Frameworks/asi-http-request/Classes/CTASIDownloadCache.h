//
//  CTASIDownloadCache.h
//  Part of CTASIHTTPRequest -> http://allseeing-i.com/CTASIHTTPRequest
//
//  Created by Ben Copsey on 01/05/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
//  Connect SDK Note:
//  CT has been prepended to all members of this framework to avoid namespace collisions
//

#import <Foundation/Foundation.h>
#import "CTASICacheDelegate.h"

@interface CTASIDownloadCache : NSObject <CTASICacheDelegate> {
	
	// The default cache policy for this cache
	// Requests that store data in the cache will use this cache policy if their cache policy is set to CTASIUseDefaultCachePolicy
	// Defaults to CTASIAskServerIfModifiedWhenStaleCachePolicy
    CTASICachePolicy defaultCachePolicy;
	
	// The directory in which cached data will be stored
	// Defaults to a directory called 'ASIHTTPRequestCache' in the temporary directory
	NSString *storagePath;
	
	// Mediates access to the cache
	NSRecursiveLock *accessLock;
	
	// When YES, the cache will look for cache-control / pragma: no-cache headers, and won't reuse store responses if it finds them
	BOOL shouldRespectCacheControlHeaders;
}

// Returns a static instance of an CTASIDownloadCache
// In most circumstances, it will make sense to use this as a global cache, rather than creating your own cache
// To make ASIHTTPRequests use it automatically, use [CTASIHTTPRequest setDefaultCache:[CTASIDownloadCache sharedCache]];
+ (id)sharedCache;

// A helper function that determines if the server has requested data should not be cached by looking at the request's response headers
+ (BOOL)serverAllowsResponseCachingForRequest:(CTASIHTTPRequest *)request;

// A list of file extensions that we know won't be readable by a webview when accessed locally
// If we're asking for a path to cache a particular url and it has one of these extensions, we change it to '.html'
+ (NSArray *)fileExtensionsToHandleAsHTML;

@property (assign, nonatomic) CTASICachePolicy defaultCachePolicy;
@property (retain, nonatomic) NSString *storagePath;
@property (atomic, retain) NSRecursiveLock *accessLock;
@property (atomic, assign) BOOL shouldRespectCacheControlHeaders;
@end
