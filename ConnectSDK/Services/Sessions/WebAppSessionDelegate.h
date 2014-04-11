//
// Created by Jeremy White on 3/26/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WebAppSession;

@protocol WebAppSessionDelegate <NSObject>

@optional

- (void) webAppSession:(WebAppSession *)webAppSession didReceiveMessage:(id)message;
- (void) webAppSessionDidDisconnect:(WebAppSession *)webAppSession;

@end
