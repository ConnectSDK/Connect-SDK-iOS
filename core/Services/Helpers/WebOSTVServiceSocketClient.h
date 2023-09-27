//
//  WebOSTVServiceSocketClient.h
//  Connect SDK
//
//  Created by Jeremy White on 6/19/14.
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
#import "ServiceCommandDelegate.h"
#import "ServiceCommand.h"
#import "LGSRWebSocket.h"

@class WebOSTVService;
@protocol WebOSTVServiceSocketClientDelegate;


@interface WebOSTVServiceSocketClient : NSObject <ServiceCommandDelegate, LGSRWebSocketDelegate>

- (instancetype) initWithService:(WebOSTVService *)service;

- (void) connect;
- (void) disconnect;
- (void) disconnectWithError:(NSError *)error;

- (ServiceSubscription *) addSubscribe:(NSURL *)URL payload:(NSDictionary *)payload success:(SuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *) killSubscribe:(NSURL *)URL payload:(NSDictionary *)payload;

- (void) sendDictionaryOverSocket:(NSDictionary *)payload;
- (void) sendStringOverSocket:(NSString *)payload;

@property (nonatomic) id<WebOSTVServiceSocketClientDelegate> delegate;
@property (nonatomic) WebOSTVService *service;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) LGSRWebSocket *socket;
@property (nonatomic, readonly) NSDictionary *activeConnections;
@property (nonatomic, readonly) NSArray *commandQueue;

@end

@protocol WebOSTVServiceSocketClientDelegate <NSObject>

- (void) socketDidConnect:(WebOSTVServiceSocketClient *)socket;
- (void) socket:(WebOSTVServiceSocketClient *)socket didCloseWithError:(NSError *)error;
- (void) socket:(WebOSTVServiceSocketClient *)socket didFailWithError:(NSError *)error;

@optional
// TODO : Deprecate this method and rename this to more meaningful one probably socketWillRequirePairingWithPairingType:
- (void) socketWillRegister:(WebOSTVServiceSocketClient *)socket;
- (void) socket:(WebOSTVServiceSocketClient *)socket registrationFailed:(NSError *)error;
- (BOOL) socket:(WebOSTVServiceSocketClient *)socket didReceiveMessage:(NSDictionary *)message;

@end
