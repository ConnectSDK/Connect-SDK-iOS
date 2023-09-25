//
//  AirPlayServiceHTTPKeepAlive.m
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

#import "AirPlayServiceHTTPKeepAlive.h"

#import "ServiceCommand.h"

@interface AirPlayServiceHTTPKeepAlive ()

/// The keep-alive timer.
@property (nonatomic, weak) NSTimer *timer;

@end


@implementation AirPlayServiceHTTPKeepAlive

#pragma mark - Init

- (instancetype)initWithInterval:(CGFloat)interval
              andCommandDelegate:(id<ServiceCommandDelegate>)commandDelegate {
    if (self = [super init]) {
        _interval = interval;
        _commandDelegate = commandDelegate;
    }
    return self;
}

- (instancetype)initWithCommandDelegate:(id<ServiceCommandDelegate>)commandDelegate {
    // Apple TV 3 disconnects after 60 seconds of inactivity in an HTTP
    // socket, so 50 seconds' keep-alive request should be enough
    return [self initWithInterval:50
               andCommandDelegate:commandDelegate];
}

- (instancetype)init {
    return [self initWithCommandDelegate:nil];
}

- (void)dealloc {
    [self stopTimer];
}

#pragma mark - Timer Management

- (void)startTimer {
    [self stopTimer];

    DLog(@"Starting keep-alive timer");
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.interval
                                                  target:self
                                                selector:@selector(sendKeepAlive:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimer {
    if (self.timer) {
        DLog(@"Stopping keep-alive timer");
        [self.timer invalidate];
        self.timer = nil;
    }
}

#pragma mark - Private Methods

- (void)sendKeepAlive:(NSTimer *)timer {
    DLog(@"Sending keep-alive request");
    NSParameterAssert(self.commandURL);

    // the "/0" resource is unlikely to change to return something, as opposed
    // to the "/" resource. a smaller response is better here
    NSURL *keepAliveURL = [self.commandURL URLByAppendingPathComponent:@"0"];
    ServiceCommand *keepAliveCommand = [ServiceCommand commandWithDelegate:self.commandDelegate
                                                                    target:keepAliveURL
                                                                   payload:nil];
    keepAliveCommand.HTTPMethod = @"GET";
    keepAliveCommand.callbackComplete = ^(id obj) {
        DLog(@"%@: keep-alive success %@", NSStringFromClass(self.class), obj);
    };
    keepAliveCommand.callbackError = ^(NSError *error) {
        DLog(@"%@: keep-alive error %@", NSStringFromClass(self.class), error);
    };
    [keepAliveCommand send];
}

@end
