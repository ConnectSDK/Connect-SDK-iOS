//
//  SubscriptionDeduplicator.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-06-05.
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

#import "SubscriptionDeduplicator.h"

@interface SubscriptionDeduplicator ()

/// Previous state of a subscription associated with this object.
@property (nonatomic, strong, readonly, nullable) id savedState;

@end

@implementation SubscriptionDeduplicator

@synthesize savedState = _savedState;

- (nonnull instancetype)runBlock:(dispatch_block_t __nonnull)block
              ifStateDidChangeTo:(id __nonnull)state {
    SubscriptionDeduplicator *nextInstance = self;

    // previous state is set and is different from current one
    // or previous state is not set
    const BOOL stateDidChange = ((self.savedState &&
                                  (![state isEqual:self.savedState])) ||
                                 !self.savedState);
    if (stateDidChange) {
        nextInstance = [[SubscriptionDeduplicator alloc] initWithState:state];
        block();
    }

    return nextInstance;
}

#pragma mark - Private Init

/// Initializes a new object with the given @c state.
- (nonnull instancetype)initWithState:(nonnull id)state {
    self = [super init];
    _savedState = state;
    return self;
}

@end
