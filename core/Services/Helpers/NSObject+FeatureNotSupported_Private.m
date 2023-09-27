//
//  NSObject+FeatureNotSupported_Private.m
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

#import "NSObject+FeatureNotSupported_Private.h"

#import "ConnectError.h"

NS_ASSUME_NONNULL_BEGIN
@implementation NSObject (FeatureNotSupported)

- (nullable ServiceSubscription *)sendNotSupportedFailure:(nullable FailureBlock)failure {
    if (failure) {
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported
                                         andDetails:nil]);
    }

    return nil;
}

@end
NS_ASSUME_NONNULL_END
