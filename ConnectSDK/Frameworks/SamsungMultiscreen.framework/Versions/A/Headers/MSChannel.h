//
//  SCChannel.h
//  ConnectIOS
//
//  Created by Andres Ortega on 9/17/13.
//  Copyright (c) 2013 Samsung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MSChannelClientList+CLIENTS.h"


/**
 *  @constant MSClientMessageNotification
 *  @since Channel API 1.0
 */
extern NSString *const MSClientMessageNotification;

/**
 *  @const MSDisconnectNotification
 *  @since Channel API 1.0
 */
extern NSString *const MSDisconnectNotification;

/**
 *  @const MSDisconnectNotification
 *  @since Channel API 1.0
 */
extern NSString *const MSClientConnectNotification;

/**
 *  @const SCClientDisconnectNotification
 *  @since Channel API 1.0
 */
extern NSString *const MSClientDisconnectNotification;

/**
 Class that represents a communication "Channel" to the TV.
 
 The channel instance emits the following notifications
 
 - `MSClientMessageNotification`:
 - `MSDisconnectNotification`:
 - `MSClientConnectNotification`:
 - `MSClientDisconnectNotification`:
 
 */
@interface MSChannel : NSObject


///---------------------------------------------------------------------------------------
/// @name Get channel info
///---------------------------------------------------------------------------------------


/**
 *  If connected to the Channel, this will return true
 */
@property (nonatomic, readonly) BOOL isConnected;

/**
 *  The identifier of the channel
 *
 *  @since Channel API 1.0
 */
@property (nonatomic, readonly) NSString *channelId;

/**
 *  A collection of clients currently connected to the channel
 *  @since Channel API 1.0
 */
@property (nonatomic, readonly) MSChannelClientList *clientList;

/**
 *  The client id
 *  @since Channel API 1.0
 */
@property (nonatomic, readonly) NSString *clientId;


///---------------------------------------------------------------------------------------
/// @name Handle connections
///---------------------------------------------------------------------------------------

/**
 *  Open a connection to the channel
 *
 *  @param completionBlock completion block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Channel API 1.0
 */
- (void)connectWithCompletionBlock:(void (^)(MSChannelClient *, NSError *)) completionBlock
                            queue:(dispatch_queue_t)queue;

/**
 *  Open a connection to the channel and set the attributes dictionary for the result client
 *
 *  @param clientAttributes attributes that will be communicated to all other clients
 *  @param completionBlock connect completion block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Channel API 1.0
 */
- (void)connectWithAttributes:(NSDictionary *)clientAttributes
    completionBlock:(void (^)(MSChannelClient *, NSError *)) completionBlock
                        queue:(dispatch_queue_t)queue;

/**
 *  Disconnect from the channel.
 *
 *  @param completionBlock Disconnect completion block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil 
 *  @since Channel API 1.0
 */
- (void)disconnectWithCompletionBlock:(void (^)()) completionBlock
                               queue:(dispatch_queue_t)queue;


///---------------------------------------------------------------------------------------
/// @name Send messages
///---------------------------------------------------------------------------------------

/**
 *  Sends a message to all peers other than self
 *
 *  @param message The message to be sent
 *  @since Channel API 1.0
 */
- (void)broadcast:(NSString *)message;

/**
 *  Sends an encrypted message to all peers other than self
 *
 *  @param message The message to be sent
 *  @param encrypt The encrypt flag, YES = encrypt the message
 *  @since Channel API 1.1.1
 */
- (void)broadcast:(NSString *)message encrypt:(BOOL)encrypt;

/**
 *  Sends a message to the host (the tv)
 *
 *  @param message The message to be sent
 *  @since Channel API 1.0
 */
- (void)sendToHost:(NSString *)message;


/**
 *  Sends an encrypted message to the host (the tv)
 *
 *  @param message The message to be sent
 *  @param encrypt The encrypt flag, YES = encrypt the message
 *  @since Channel API 1.0
 */
- (void)sendToHost:(NSString *)message encrypt:(BOOL)encrypt;

/**
 *  Sends a message to all connected peers other than the host (the tv)
 *
 *  @param message The message to be sent
 *  @since Channel API 1.0
 */
- (void)sendToClients:(NSString *)message;

/**
 *  Sends an encrypted message to all connected peers other than the host (the tv)
 *
 *  @param message The message to be sent
 *  @param encrypt The encrypt flag, YES = encrypt the message
 *  @since Channel API 1.0
 */
- (void)sendToClients:(NSString *)message encrypt:(BOOL)encrypt;

/**
 *  Sends a message to all connected peers, including the host (the tv) and self
 *
 *  @param message The message to be sent
 *  @since Channel API 1.0
 */
- (void)sendToAll:(NSString *)message;

/**
 *  Sends an encrypted message to all connected peers, including the host (the tv) and self
 *
 *  @param message The message to be sent
 *  @param encrypt The encrypt flag, YES = encrypt the message
 *  @since Channel API 1.0
 */
- (void)sendToAll:(NSString *)message encrypt:(BOOL)encrypt;

/**
 *  Sends a message to the target, target can be either an array of 
 *  MSChannelClient or an array of NSString clientIds
 *
 *  @param to The target
 *  @param message The message to be sent
 *  @since Channel API 1.0
 */
- (void)sendTo:(id)to message:(NSString *)message;

/**
 *  Sends an encrypted message to the target, target can be either an array of
 *  MSChannelClient or an array of NSString clientIds
 *
 *  @param to The target
 *  @param message The message to be sent
 *  @param encrypt The encrypt flag, YES = encrypt the message
 *  @since Channel API 1.0
 */
- (void)sendTo:(id)to message:(NSString *)message encrypt:(BOOL)encrypt;

@end
