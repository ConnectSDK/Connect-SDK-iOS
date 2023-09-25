//
// Created by Jeremy White on 4/14/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
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
