//
//  SCDevice.h
//  SamsungConnect
//
//  Created by Andres Ortega on 10/1/13.
//  Copyright (c) 2013 Samsung. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const API_VERSION;

@class MSApplication;
@class MSChannel;

/**
 *  The Device class represents a Samsung Multiscreen capable device, traditionally on the remote device, but can be local as well. This class is used to control and retrieve information about the device.
 */
@interface MSDevice : NSObject

///---------------------------------------------------------------------------------------
/// @name Get Device info
///---------------------------------------------------------------------------------------

/**
* The attributes associated with the device
*  @since Device API 1.0
*/
@property (nonatomic, readonly) NSDictionary *attributes;

/**
 *  The ip address of the device
 *  @since Device API 1.0
 */
@property (nonatomic, readonly) NSString *ipAddress;


/**
 *  The friendly name of the device if known
 *  @since Device API 1.0
 */
@property (nonatomic, readonly) NSString *name;

/**
 *  The id associated with the device
 *  @since Device API 1.0
 */
@property (nonatomic, readonly) NSString *deviceId;

/**
 *  The root api endpoint for the device
 *
 *  Use private method serviceURI instead
 *  @since Device API 1.0
 */
@property (nonatomic, readonly) NSString *serviceURI;

/**
 *  The network type of the device if known
 *  @since Device API 1.0
 */
@property (nonatomic, readonly) NSString *networkType;

/**
 *  The network SSID
 *  @since Device API 1.0
 */
@property (nonatomic, readonly) NSString *ssid;

///---------------------------------------------------------------------------------------
/// @name Discover devices
///---------------------------------------------------------------------------------------

/**
 *  Retrieves an array of devices
 *
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
+ (void)searchWithCompletionBlock:(void (^)(NSArray *devices))completionBlock
                            queue:(dispatch_queue_t)queue;

/**
 *  Retrieves a device instance by a pincode using cloud discovery
 *
 *  @param pincode         The user provided code
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
+ (void)getByCode:(NSString *)pincode
  completionBlock:(void (^)(MSDevice *device, NSError *error))completionBlock
            queue:(dispatch_queue_t)queue;

/**
 *  Retrieves a device instance
 *
 *  @param serviceURI      The host endpoint of the application
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
+ (void)getDeviceforURI:(NSString *)serviceURI
  completionBlock:(void (^)(MSDevice *device, NSError *error))completionBlock
            queue:(dispatch_queue_t)queue;


///---------------------------------------------------------------------------------------
/// @name Get applications
///---------------------------------------------------------------------------------------

/**
 *  Retrieves information about an application by run title
 *
 *  @param runTitle        The run title id
 *  @param completionBlock The callback handler block
 *  @param queue           Device API 1.0
 */
- (void)getApplication:(NSString *)runTitle
      completionBlock:(void (^)(MSApplication *application,NSError *error))completionBlock
                queue:(dispatch_queue_t)queue;

///---------------------------------------------------------------------------------------
/// @name System UI pincode
///---------------------------------------------------------------------------------------

/**
 *  Displays the current pin code for the device using the device's system UI
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)showPincodeWithCompletionBlock:(void (^)(BOOL success))completionBlock
                                 queue:(dispatch_queue_t)queue;

/**
 *  Hides the pincode being shown in the device's system UI
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)hidePinCodeWithCompletionBlock:(void (^)(BOOL success))completionBlock
                                 queue:(dispatch_queue_t)queue;


///---------------------------------------------------------------------------------------
/// @name Channel Methods
///---------------------------------------------------------------------------------------

/**
 *  Retrieves a channel instance
 *
 *  @param channelId       The id of the channel
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)connectToChannel:(NSString *)channelId
         completionBlock:(void (^)(MSChannel *channel, NSError *error))completionBlock
                   queue:(dispatch_queue_t)queue;

/**
 *  Retrieves a channel instance
 *
 *  @param channelId       The id of the channel
 *  @param clientAttributes attributes that will be communicated to all other clients
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)connectToChannel:(NSString *)channelId
        clientAttributes:(NSDictionary *)clientAttributes
         completionBlock:(void (^)(MSChannel *channel, NSError *error))completionBlock
                   queue:(dispatch_queue_t)queue;

@end
