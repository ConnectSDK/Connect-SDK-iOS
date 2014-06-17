//
//  MSApplication.h
//  SamsungMultiscreen
//
//  Created by Andres Ortega on 11/27/13.
//  Copyright (c) 2013 Samsung. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum MS_APPLICATION_STATUS {
    MS_APP_STOPPED,
    MS_APP_STARTING,
    MS_APP_RUNNING,
    MS_APP_INSTALLABLE
} MS_APPLICATION_STATUS;

@class MSDevice;
@class MSChannel;

/**
 *  This class represents a tv multiscreen application
 */
@interface MSApplication : NSObject

/**
 *  The device that is hosting the application
 */
@property (readonly) MSDevice *device;

/**
 *  The last known status
 *
 *  The status is updated after [device getApplication] or after [application getStatusWithCompletionBlock]
 */
@property (readonly) MS_APPLICATION_STATUS lastKnownStatus;

/**
 *  Launches an application on the device if it is currently installed
 *
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)launchWithCompletionBlock:(void (^)(BOOL success, NSError *error)) completionBlock
                            queue:(dispatch_queue_t)queue;

/**
 *  Launches an application on the device if it is currently installed
 *
 *  @param options Startup application parameters dictionary
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)launchWithOptions:(NSDictionary *)options
          completionBlock:(void (^)(BOOL success, NSError *error)) completionBlock
                    queue:(dispatch_queue_t)queue;


/**
 *  Terminates an application on the device if it is currently running
 *
 *  @param completionBlock The callback handler block
 *  @param queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 *  @since Device API 1.0
 */
- (void)terminateWithCompletionBlock:(void (^)(BOOL success, NSError *error)) completionBlock
                                queue:(dispatch_queue_t)queue;

/**
 *  Starts the installation process of an application identified by run title
 *
 *  @param completionBlock The callback handler block
 *  @param queue           Device API 1.0
 */
- (void)installWithCompletionBlock:(void (^)(BOOL success, NSError *error))completionBlock
                    queue:(dispatch_queue_t)queue;


/**
 *  Get the status of the application
 *
 *  @param completionBlock The callback handler block
 *  @param queue queue The queue in which the block will be executed, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) is used when that param is nil
 */
- (void)updateStatusWithCompletionBlock:(void (^)(MS_APPLICATION_STATUS, NSError *error)) completionBlock
                               queue:(dispatch_queue_t)queue;



@end
