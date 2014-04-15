//
//  WebAppSessionDelegate.h
//  Connect SDK
//
//  Created by Jeremy White on 3/26/14.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
