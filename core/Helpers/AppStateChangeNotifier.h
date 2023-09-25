//
//  AppStateChangeNotifier.h
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

#import <Foundation/Foundation.h>

@protocol BlockRunner;

NS_ASSUME_NONNULL_BEGIN
/**
 * Listens to app state change events (didEnterBackground and didBecomeActive,
 * in particular) and allows other components be notified about them using a
 * simpler API.
 */
@interface AppStateChangeNotifier : NSObject

/// Type of a block that is called on an app state change event.
typedef void (^AppStateChangeBlock)();

/// The block is called when the app has entered background.
@property (nonatomic, copy, nullable) AppStateChangeBlock didBackgroundBlock;

/// The block is called when the app has entered foreground.
@property (nonatomic, copy, nullable) AppStateChangeBlock didForegroundBlock;

/// The @c BlockRunner instance specifying where to run the blocks. The
/// default value is the main dispatch queue runner. Cannot be @c nil, as it
/// will reset to the default value.
@property (nonatomic, strong) id<BlockRunner> blockRunner;


/// Starts listening for app state change events. This method is idempotent.
/// @warning You @b MUST call @c -stopListening for this object to be removed.
- (void)startListening;

/// Stops listening for app state change events. This method is idempotent.
/// @warning This method @b MUST be called to @c dealloc this object if you
/// called @c -startListening before.
- (void)stopListening;

@end
NS_ASSUME_NONNULL_END
