//
//  NSMutableDictionary+NilSafe.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSMutableDictionary (NilSafe)

/// Sets the @c object for the @c key; if @c object is @c nil, does nothing.
- (void)setNullableObject:(nullable id)object forKey:(id<NSCopying>)key;

@end
NS_ASSUME_NONNULL_END
