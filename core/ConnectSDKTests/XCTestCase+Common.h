//
//  XCTestCase+Common.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-31.
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

#import "Capability.h"

@interface XCTestCase (Common)

/**
 * A block type that should do an action on an SUT (system under test) and use
 * the provided block verifiers as the callbacks to verify they are
 * called/not called according to the check method.
 */
typedef void(^ActionBlock)(SuccessBlock successVerifier,
                           FailureBlock failureVerifier);

/**
 * Checks that the @c FailureBlock of the operation done in the @c block is
 * called with the @c ConnectStatusCodeNotSupported error code.
 */
- (void)checkOperationShouldReturnNotSupportedErrorUsingBlock:(ActionBlock)block;

@end
