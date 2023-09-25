//
//  DispatchQueueBlockRunner.h
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

#import "BlockRunner.h"

NS_ASSUME_NONNULL_BEGIN
/// Dispatches a @c block asynchronously on the given @c dispatch_queue_t queue.
/// @warning Please use the @c -initWithDispatchQueue: initializer, because you
/// must specify the @c queue.
@interface DispatchQueueBlockRunner : NSObject <BlockRunner>

/// Designated initializer. Initializes the object with the given
/// <tt>dispatch queue</tt> which will run the blocks. The @c queue must not be
/// @c nil.
- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue;

/// Convenience method that returns a block runner with the main dispatch queue.
+ (instancetype)mainQueueRunner;

@end
NS_ASSUME_NONNULL_END
