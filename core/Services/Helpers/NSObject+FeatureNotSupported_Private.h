//
//  NSObject+FeatureNotSupported_Private.h
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

@class ServiceSubscription;

NS_ASSUME_NONNULL_BEGIN
@interface NSObject (FeatureNotSupported)

/**
 * Calls the @c failure block with an unsupported error. Returns @c nil.
 *
 * @remarks It would be better to define this category on @c DeviceService
 * class, but a couple of other classes use this method as well.
 */
- (nullable ServiceSubscription *)sendNotSupportedFailure:(nullable FailureBlock)failure;

@end
NS_ASSUME_NONNULL_END
