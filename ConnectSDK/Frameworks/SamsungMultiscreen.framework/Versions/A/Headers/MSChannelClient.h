//
//  SCChannelClient.h
//  ConnectIOS
//
//  Created by Andres Ortega on 9/17/13.
//  Copyright (c) 2013 Samsung. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MSChannel;

/**
 * Represents a "client" connected to a channel.
 */
@interface MSChannelClient : NSObject

///---------------------------------------------------------------------------------------
/// @name Get user defined attributes
///---------------------------------------------------------------------------------------

/**
 * Returns a set of attributes that the client supplied in the Channel.connect method.
 * 
 * @see [MSChannel connectWithAttributes:completionBlock:queue:]
 */
@property (nonatomic, readonly) NSDictionary *attributes;

///---------------------------------------------------------------------------------------
/// @name Get client info
///---------------------------------------------------------------------------------------

/**
 *  Returns the unique id of the client.
 */
@property (nonatomic, readonly) NSString *clientId;

/**
 *  Returns the time (in milliseconds) of when the client connected to the channel. Set according to the time on the tv.
 */
@property (nonatomic, readonly) NSInteger connectTime;


///---------------------------------------------------------------------------------------
/// @name Identifying the client
///---------------------------------------------------------------------------------------

/**
 * Utility to determine if a client object is "self"
 */
@property (nonatomic, readonly) BOOL isMe;

/**
 * Determines if the client is the Channel "Host" (the tv)
 */
@property (nonatomic, readonly) BOOL isHost;

///---------------------------------------------------------------------------------------
/// @name Send messages
///---------------------------------------------------------------------------------------

/**
 *  Sends a message to this client.
 *
 *  @param message The message to be sent
 */
- (void)send:(NSString *)message;

/**
 *  Sends a message to this client.
 *
 *  @param message The message to be sent
 *  @param encrypt The encrypt flag, YES = encrypt the message
 */
- (void)send:(NSString *)message encrypt:(BOOL)encrypt;

@end
