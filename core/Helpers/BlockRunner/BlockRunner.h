//
//  BlockRunner.h
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

#import <Foundation/Foundation.h>

/**
 * Abstracts and encapsulates asynchrony, that is how and where blocks are run.
 * Using this protocol, you can easily change which dispatch queue or
 * @c NSOperationQueue delegate blocks are run on, instead of hard-coding
 * <tt>dispatch_async(dispatch_get_main_queue(), ^{ });</tt>. For example:
 *
@code
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
AppStateChangeNotifier *notifier = [AppStateChangeNotifier new];
notifier.blockRunner = [[DispatchQueueBlockRunner alloc] initWithDispatchQueue:queue];
@endcode
 *
 * Another great use case is turning asynchronous tests into synchronous, making
 * them faster and easier:
 *
@code
- (void)testStartListeningShouldSubscribeToDidBackgroundEvent {
    AppStateChangeNotifier *notifier = [AppStateChangeNotifier new];
    notifier.blockRunner = [SynchronousBlockRunner new];
    [notifier startListening];

    __block BOOL verified = NO;
    notifier.didBackgroundBlock = ^{
        verified = YES;
    };
    [self postNotificationName:UIApplicationDidEnterBackgroundNotification];

    XCTAssertTrue(verified, @"didBackgroundBlock should be called");
}
@endcode
 *
 * Here we use the synchronous block runner (instead of the default
 * asynchronous, main queue one) to avoid writing asynchronous tests with
 * @c XCTestExpectation.
 */
@protocol BlockRunner <NSObject>
@required

/// A type for blocks without arguments and no return value.
typedef void(^VoidBlock)(void);

/**
 * Runs the given @c block somewhere, depending on the concrete implementation.
 * @param block block to run; must not be @c nil.
 */
- (void)runBlock:(nonnull VoidBlock)block;

@end
