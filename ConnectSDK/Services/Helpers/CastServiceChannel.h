//
// Created by Jeremy White on 2/20/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleCast/GoogleCast.h>
#import "Capability.h"
#import "WebAppLauncher.h"

@class CastWebAppSession;

@interface CastServiceChannel : GCKCastChannel

@property (nonatomic, copy) SuccessBlock connectionSuccess;
@property (nonatomic, copy) FailureBlock connectionFailure;

- (id)initWithAppId:(NSString *)appId session:(CastWebAppSession *)session;

@end
