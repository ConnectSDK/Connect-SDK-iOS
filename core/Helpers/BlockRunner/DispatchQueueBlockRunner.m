//
//  DispatchQueueBlockRunner.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/4/15.
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

#import "DispatchQueueBlockRunner.h"
#import "CommonMacros.h"

@interface DispatchQueueBlockRunner ()

@property (nonatomic, strong, readonly) dispatch_queue_t queue;

@end

@implementation DispatchQueueBlockRunner

#pragma mark - Init

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
    if ((self = [super init])) {
        _assert_state(nil != queue, @"nil queue is not accepted");
        _queue = queue;
    }

    return self;
}

- (instancetype)init {
    _assert_state(NO, @"Please use the -initWithDispatchQueue: initializer");
    return nil;
}

#pragma mark - Public Methods

- (void)runBlock:(nonnull VoidBlock)block {
    _assert_state(nil != block, @"nil block is not accepted");
    dispatch_async(self.queue, block);
}

+ (instancetype)mainQueueRunner {
    return [[[self class] alloc] initWithDispatchQueue:dispatch_get_main_queue()];
}

#pragma mark - Equality

- (BOOL)isEqual:(id)object {
    DispatchQueueBlockRunner *other = object;
    return self.queue == other.queue;
}

- (NSUInteger)hash {
    return self.queue.hash;
}

@end
