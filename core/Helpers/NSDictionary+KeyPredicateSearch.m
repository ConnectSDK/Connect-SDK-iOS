//
//  NSDictionary+KeyPredicateSearch.m
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

#import "NSDictionary+KeyPredicateSearch.h"

@implementation NSDictionary (KeyPredicateSearch)

- (id)objectForKeyWithPredicate:(NSPredicate *)predicate {
    if (!predicate) {
        return nil;
    }

    NSArray *predicateKeys = [self.allKeys filteredArrayUsingPredicate:predicate];
    if (predicateKeys.count > 1) {
        NSString *reason = [NSString stringWithFormat:@"There are %ld object for predicate %@",
                            (unsigned long)predicateKeys.count, predicate];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:reason
                                     userInfo:nil];
    }
    return self[predicateKeys.firstObject];
}

- (id)objectForKeyEndingWithString:(NSString *)string {
    return [self objectForKeyWithPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH %@", string]];
}

@end
