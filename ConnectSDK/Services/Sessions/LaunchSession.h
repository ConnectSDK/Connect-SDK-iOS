//
// Created by Jeremy White on 1/28/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "JSONObjectCoding.h"

@class DeviceService;


typedef enum
{
    LaunchSessionTypeUnknown,
    LaunchSessionTypeApp,
    LaunchSessionTypeExternalInputPicker,
    LaunchSessionTypeMedia,
    LaunchSessionTypeWebApp
} LaunchSessionType;

@interface LaunchSession : NSObject

@property (nonatomic, strong) NSString *appId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, strong) id rawData;

@property (nonatomic) LaunchSessionType sessionType;
@property (nonatomic, weak) DeviceService *service;


- (BOOL)isEqual:(LaunchSession *)launchSession;

+ (LaunchSession *) launchSessionForAppId:(NSString *)appId;
+ (LaunchSession *) launchSessionFromJSONObject:(NSDictionary *)dict;
- (NSDictionary *) toJSONObject;

- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@end
