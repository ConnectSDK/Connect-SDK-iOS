//
// Created by Jiang Lu on 14-4-8.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MSFKErrorCode) {
    
    /**
     * Error code indicating a network I/O error.
     */
    MSFKErrorCodeNetworkError = 1,
    
    /**
     * Error code indicating that an operation has timed out.
     */
    MSFKErrorCodeTimeout = 2,
    
    /**
     * Error code indicating an authentication error.
     */
    MSFKErrorCodeDeviceAuthenticationFailure = 3,
    
    /**
     * Error code indicating that an invalid request was made.
     */
    MSFKErrorCodeInvalidRequest = 4,
    
    /**
     * Error code indicating that an in-progress request has been cancelled, most likely because
     * another action has preempted it.
     */
    MSFKErrorCodeCancelled = 5,
    
    /**
     * Error code indicating that the request was disallowed and could not be completed.
     */
    MSFKErrorCodeNotAllowed = 6,
    
    /**
     * Error code indicating that a requested application could not be found.
     */
    MSFKErrorCodeApplicationNotFound = 7,
    
    /**
     * Error code indicating that a requested application is not currently running.
     */
    MSFKErrorCodeApplicationNotRunning = 8,
    
    /**
     * Error code indicating the app entered the bMSFKground.
     */
    MSFKErrorCodeAppDidEnterBackground = 91,
    
    /**
     * Error code indicating a disconnection occurred during the request.
     */
    MSFKErrorCodeDisconnected = 92,
    
    /**
     * Error code indicating that a request could not be made because the same type of request is
     * still in process.
     */
    MSFKErrorCodeDuplicateRequest = 93,
    
    /**
     * Error code indicating that a media load failed on the receiver side.
     */
    MSFKErrorCodeMediaLoadFailed = 94,
    
    /**
     * Error code indicating that a media media command failed because of the media player state.
     */
    MSFKErrorCodeInvalidMediaPlayerState = 95,
    
    /**
     * Error code indicating that an unknown, unexpected error has occurred.
     */
    MSFKErrorCodeUnknown = 99,
};

/**
 * The key for the customData JSON object associated with the error in the userInfo dictionary.
 */
extern NSString *const kMSFKErrorCustomDataKey;

/**
 * The class for all MSFK framework errors.
 *
 * @ingroup Utilities
 */
@interface MSFKError : NSError

/**
 * Returns the name of the enum value for a given error code.
 */
+ (NSString *)enumDescriptionForCode:(MSFKErrorCode)code;

/** @cond INTERNAL */

/**
 * Designated initializer.
 */
- (id)initWithCode:(MSFKErrorCode)code additionalUserInfo:(NSDictionary *)additionalUserInfo;

- (id)initWithCode:(MSFKErrorCode)code;

/** @endcond */

@end