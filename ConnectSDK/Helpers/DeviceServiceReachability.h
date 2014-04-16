//
// Created by Jeremy White on 4/14/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DeviceServiceReachabilityDelegate;

@interface DeviceServiceReachability : NSObject

- (instancetype) initWithTargetURL:(NSURL *)targetURL;
+ (instancetype) reachabilityWithTargetURL:(NSURL *)targetURL;

- (void) start;
- (void) stop;

@property (nonatomic, readonly) NSURL *targetURL;
@property (nonatomic) BOOL running;
@property (nonatomic) id<DeviceServiceReachabilityDelegate> delegate;

@end

@protocol DeviceServiceReachabilityDelegate

- (void) didLoseReachability:(DeviceServiceReachability *)reachability;

@end
