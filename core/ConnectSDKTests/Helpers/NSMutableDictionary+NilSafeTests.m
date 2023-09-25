//
//  NSMutableDictionary+NilSafeTests.m
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

@interface NSMutableDictionary_NilSafeTests : XCTestCase

@property(nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation NSMutableDictionary_NilSafeTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    self.dict = [NSMutableDictionary dictionary];
}

#pragma mark - Tests

- (void)testShouldSetNotNullObject {
    [self.dict setNullableObject:@42 forKey:@"key"];
    XCTAssertEqualObjects(self.dict[@"key"], @42);
}

- (void)testShouldNotSetNil {
    [self.dict setNullableObject:nil forKey:@"key"];
    XCTAssertNil(self.dict[@"key"]);
}

- (void)testNonNullObjectShouldOverwriteExistingObject {
    self.dict[@"key"] = @0;
    [self.dict setNullableObject:@42 forKey:@"key"];
    XCTAssertEqualObjects(self.dict[@"key"], @42);
}

- (void)testNilObjectShouldNotOverwriteExistingObject {
    self.dict[@"key"] = @0;
    [self.dict setNullableObject:nil forKey:@"key"];
    XCTAssertEqualObjects(self.dict[@"key"], @0);
}

@end
