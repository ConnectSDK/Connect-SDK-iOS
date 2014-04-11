//
//  ServiceCommandDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
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
