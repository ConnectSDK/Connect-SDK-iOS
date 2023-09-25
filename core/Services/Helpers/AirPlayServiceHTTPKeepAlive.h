//
//  AirPlayServiceHTTPKeepAlive.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 12/17/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
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

@import Foundation;
@import CoreGraphics;

@protocol ServiceCommandDelegate;

/// The class is responsible for maintaining an AirPlay connection alive by
/// sending periodic requests.
@interface AirPlayServiceHTTPKeepAlive : NSObject

/// The interval between keep-alive requests, in seconds. 50 by default.
@property (nonatomic, assign) CGFloat interval;

/// An object that sends AirPlay commands.
@property (nonatomic, weak) id<ServiceCommandDelegate> commandDelegate;

/// The base URL for commands.
@property (nonatomic, strong) NSURL *commandURL;


/// Designated initializer, setting the interval and command delegate.
- (instancetype)initWithInterval:(CGFloat)interval
              andCommandDelegate:(id<ServiceCommandDelegate>)commandDelegate;

/// Initializer that sets the command delegate.
- (instancetype)initWithCommandDelegate:(id<ServiceCommandDelegate>)commandDelegate;

/// Schedules sending keep-alive requests. The first one will be sent after the
/// specified @c interval.
- (void)startTimer;

/// Stops sending keep-alive requests.
- (void)stopTimer;

@end
