//
//  EXPMatchers+matchRegex.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/26/15.
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

#import "EXPMatchers+matchRegex.h"

EXPMatcherImplementationBegin(matchRegex, (NSString *expected)) {
    match(^BOOL {
        NSString *string = actual;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expected
                                                                               options:0
                                                                                 error:nil];
        NSRange wholeRange = NSMakeRange(0, string.length);
        NSRange matchedRange = [regex rangeOfFirstMatchInString:string
                                                        options:NSMatchingAnchored
                                                          range:wholeRange];
        return NSEqualRanges(matchedRange, wholeRange);
    });

    failureMessageForTo(^NSString * {
        return [NSString stringWithFormat:
                @"expected: a string matching regex %@, got: %@",
                expected, actual];
    });
}
EXPMatcherImplementationEnd
