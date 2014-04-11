//
// Created by Jeremy White on 2/21/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "DeviceService.h"
#import "MediaControl.h"
#import "ServiceCommandDelegate.h"
#import "LaunchSession.h"
#import "WebAppSessionDelegate.h"

typedef enum {
    WebAppStatusOpen,
    WebAppStatusBackground,
    WebAppStatusForeground,
    WebAppStatusClosed
} WebAppStatus;

@interface WebAppSession : NSObject <ServiceCommandDelegate, MediaControl, JSONObjectCoding>

typedef void (^ WebAppMessageBlock)(id message); // message will be either an NSString or NSDictionary (JSON object)
typedef void (^ WebAppStatusBlock)(WebAppStatus status);

@property (nonatomic, strong) LaunchSession *launchSession;
@property (nonatomic, readonly) DeviceService *service;

- (id) initWithLaunchSession:(LaunchSession *)launchSession service:(DeviceService *)service;

- (ServiceSubscription *) subscribeWebAppStatus:(WebAppStatusBlock)success failure:(FailureBlock)failure;
- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

#pragma mark - Connection handling
- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) disconnectFromWebApp;

#pragma mark - Communication
@property (nonatomic, strong) id<WebAppSessionDelegate> delegate;

- (void) sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
