//
//  AppStateChangeNotifier.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/15/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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

#import "AppStateChangeNotifier.h"

#import <UIKit/UIKit.h>

#import "DispatchQueueBlockRunner.h"

@interface AppStateChangeNotifier ()

/// Stores an observer handle for @c UIApplicationDidEnterBackgroundNotification
/// if subscribed.
@property (strong) id<NSObject> backgroundObserverHandle;
/// Stores an observer handle for @c UIApplicationDidBecomeActiveNotification
/// if subscribed.
@property (strong) id<NSObject> foregroundObserverHandle;

@end

@implementation AppStateChangeNotifier

#pragma mark - Public Methods

- (void)startListening {
    // both should be either subscribed or not
    const BOOL alreadySubscribed = (self.backgroundObserverHandle ||
                                    self.foregroundObserverHandle);
    if (!alreadySubscribed) {
        // the queue is retained by the NSNotificationCenter, and is released
        // in -stopListening
        NSOperationQueue *queue = [NSOperationQueue new];
        queue.maxConcurrentOperationCount = 1;
        queue.name = [NSString stringWithFormat:@"%@ notification queue", self];

        self.backgroundObserverHandle = ({
            [[self center] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                       object:[UIApplication sharedApplication]
                                        queue:queue
                                   usingBlock:^(NSNotification *note) {
                                       [self runStateChangeBlock:
                                        self.didBackgroundBlock];
                                   }];
        });

        self.foregroundObserverHandle = ({
            [[self center] addObserverForName:UIApplicationDidBecomeActiveNotification
                                       object:[UIApplication sharedApplication]
                                        queue:queue
                                   usingBlock:^(NSNotification *note) {
                                       [self runStateChangeBlock:
                                        self.didForegroundBlock];
                                   }];
        });
    }
}

- (void)stopListening {
    [[self center] removeObserver:self.backgroundObserverHandle];
    self.backgroundObserverHandle = nil;

    [[self center] removeObserver:self.foregroundObserverHandle];
    self.foregroundObserverHandle = nil;
}

- (id<BlockRunner> __nonnull)blockRunner {
    if (!_blockRunner) {
        _blockRunner = [DispatchQueueBlockRunner mainQueueRunner];
    }

    return _blockRunner;
}

#pragma mark - Helpers

/// Returns a @c NSNotificationCenter used by the class.
- (NSNotificationCenter *)center {
    return [NSNotificationCenter defaultCenter];
}

/// Runs the given @c AppStateChangeBlock if not @c nil.
- (void)runStateChangeBlock:(nullable AppStateChangeBlock)block {
    if (block) {
        [self.blockRunner runBlock:block];
    }
}

@end
