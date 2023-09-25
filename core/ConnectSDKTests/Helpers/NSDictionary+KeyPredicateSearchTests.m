//
//  NSDictionary+KeyPredicateSearchTests.m
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

/// Tests for the @c NSDictionary+KeyPredicateSearch category.
@interface NSDictionary_KeyPredicateSearchTests : XCTestCase

@property (nonatomic, strong) NSDictionary *sampleDict;

@end

@implementation NSDictionary_KeyPredicateSearchTests

- (void)setUp {
    [super setUp];
    self.sampleDict = @{@"ab:cd": @42,
                        @"ef:hg": @100,
                        @"something": @"else"};
}

#pragma mark - Key Predicate Search Tests

/// Tests that @c -objectForKeyWithPredicate: returns the object for a key that
/// matches the predicate.
- (void)testMatchingKeyShouldReturnValue {
    id object = [self.sampleDict objectForKeyWithPredicate:
                 [NSPredicate predicateWithFormat:@"self contains %@", @"b:c"]];
    XCTAssertEqualObjects(object, @42, @"The found object is wrong");
}

/// Tests that @c -objectForKeyWithPredicate: throws an exception when two
/// matching keys are found in the dictionary.
- (void)testTwoMatchingKeysShouldThrowException {
    XCTAssertThrows(([self.sampleDict objectForKeyWithPredicate:
                      [NSPredicate predicateWithFormat:@"self contains %@", @"e"]]),
                    @"More than one matching key should throw an exception");
}

/// @c -objectForKeyWithPredicate: should return @c nil when the predicate is
/// @c nil.
- (void)testNilPredicateShouldReturnNil {
    XCTAssertNil([self.sampleDict objectForKeyWithPredicate:nil],
                 @"Nil predicate should return nil object");
}

/// @c -objectForKeyWithPredicate: should return @c nil when there is no key
/// matching the predicate.
- (void)testNotMatchingPredicateShouldReturnNil {
    XCTAssertNil(([self.sampleDict objectForKeyWithPredicate:
                   [NSPredicate predicateWithFormat:@"self beginswith %@", @"aaa"]]),
                 @"Dictionary not containing a matching key should return nil");
}

#pragma mark - Key Ending With String Search Tests

/// @c -objectForKeyEndingWithString: should return the object for a key ending
/// with the given string.
- (void)testKeyEndingWithStringShouldReturnValue {
    id object = [self.sampleDict objectForKeyEndingWithString:@":cd"];
    XCTAssertEqualObjects(object, @42, @"The found object is wrong");
}

/// @c -objectForKeyEndingWithString: should throw an exception when two keys
/// end with the given string.
- (void)testTwoMatchingKeysEndingWithStringShouldThrowException {
    XCTAssertThrows([self.sampleDict objectForKeyEndingWithString:@"g"],
                    @"More than one matching key should throw an exception");
}

/// @c -objectForKeyEndingWithString: should return @c nil when the string is
/// empty.
- (void)testKeyEndingWithEmptyStringShouldReturnNil {
    XCTAssertNil([self.sampleDict objectForKeyEndingWithString:@""],
                 @"Keys ending with empty string should return nil");
}

/// @c -objectForKeyEndingWithString: should return nil when the string is
/// @c nil.
- (void)testKeyEndingWithNilStringShouldReturnNil {
    XCTAssertNil([self.sampleDict objectForKeyEndingWithString:nil],
                 @"Keys ending with nil string should return nil");
}

/// @c -objectForKeyEndingWithString: should return @c nil if no keys ending
/// with the given string found.
- (void)testNotMatchingKeyEndingWithStringShouldReturnNil {
    XCTAssertNil([self.sampleDict objectForKeyEndingWithString:@"bbb"],
                 @"Not matching keys ending with string should return nil");
}

@end
