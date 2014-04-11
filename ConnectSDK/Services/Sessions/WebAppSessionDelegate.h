//
// Created by Jeremy White on 3/26/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WebAppSession;

/*!
 * WebAppSessionDelegate provides callback methods for receiving messages from a running web app.
 */
@protocol WebAppSessionDelegate <NSObject>

@optional

/*!
 * This method is called when a message is received from a web app.
 *
 * @param webAppSession WebAppSession that corresponds to the web app that sent the message
 * @param message Message from the web app, either an NSString or a JSON object in the form of an NSDictionary
 */
- (void) webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message;

/*!
 * This method is called when a web app's communication channel (WebSocket, etc) has become disconnected.
 *
 * @param webAppSession WebAppSession that became disconnected
 */
- (void) webAppSessionDidDisconnect:(WebAppSession *)webAppSession;

@end
