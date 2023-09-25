//
//  NSDictionary+KeyPredicateSearch.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/13/15.
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
 * Extends the NSDictionary interface to be able to get objects by keys
 * matching a predicate.
 */
@interface NSDictionary (KeyPredicateSearch)

/// Returns an object for a key which name matches the given predicate.
/// @warning There must be at most one matching key in the dictionary.
- (id)objectForKeyWithPredicate:(NSPredicate *)predicate;

/// Returns an object for a key which name ends with the given string.
/// @warning There must be at most one matching key in the dictionary.
- (id)objectForKeyEndingWithString:(NSString *)string;

@end
