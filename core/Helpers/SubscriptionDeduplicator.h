//
//  SubscriptionDeduplicator.h
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

NS_ASSUME_NONNULL_BEGIN
/**
 * Deduplicates subscription notifications with the same state. The state can be
 * of any class, allowing <tt>NSNumber</tt>-wrapped values.
 * @remarks It's an immutable class.
 */
@interface SubscriptionDeduplicator : NSObject

/**
 * If the new @c state is different from the previous one, runs the @c block
 * synchronously.
 * @return a new instance that you should save to track the new state.
 */
- (instancetype)runBlock:(dispatch_block_t)block
      ifStateDidChangeTo:(id)newState;

@end
NS_ASSUME_NONNULL_END
