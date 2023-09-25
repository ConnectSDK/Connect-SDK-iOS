//
//  NSMutableDictionary+NilSafe.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-23.
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

#import "NSMutableDictionary+NilSafe.h"

NS_ASSUME_NONNULL_BEGIN
@implementation NSMutableDictionary (NilSafe)

- (void)setNullableObject:(nullable id)object forKey:(id<NSCopying>)key {
    if (object) {
        self[key] = object;
    }
}

@end
NS_ASSUME_NONNULL_END
