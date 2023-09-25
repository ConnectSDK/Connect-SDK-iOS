//
//  ServiceCommandDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
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

@class ServiceCommand;
@class ServiceSubscription;
@class ServiceAsyncCommand;

@protocol ServiceCommandDelegate <NSObject>

typedef enum {
    ServiceSubscriptionTypeUnsubscribe = NO,
    ServiceSubscriptionTypeSubscribe = YES
} ServiceSubscriptionType;

@optional

- (int) sendCommand:(ServiceCommand *)comm withPayload:(id)payload toURL:(NSURL*)URL;
- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId;
- (int) sendAsync:(ServiceAsyncCommand *)async withPayload:(id)payload toURL:(NSURL*)URL;

@end
