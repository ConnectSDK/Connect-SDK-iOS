//
//  SynchronousBlockRunnerTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/4/15.
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

#import "SynchronousBlockRunner.h"

@interface SynchronousBlockRunnerTests : XCTestCase

@property (strong) SynchronousBlockRunner *runner;

@end

@implementation SynchronousBlockRunnerTests

- (void)setUp {
    [super setUp];

    self.runner = [SynchronousBlockRunner new];
}

- (void)tearDown {
    self.runner = nil;

    [super tearDown];
}

- (void)testClassShouldImplementBlockRunner {
    XCTAssertTrue([self.runner.class conformsToProtocol:@protocol(BlockRunner)]);
}

- (void)testNilBlockShouldNotBeAccepted {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.runner runBlock:nil], @"nil block is not accepted");
#pragma clang diagnostic pop
}

- (void)testBlockShouldBeRunSynchronously {
    __block NSUInteger testValue = 0;
    void(^incrementValueBlock)(void) = ^{
        ++testValue;
    };
    [self.runner runBlock:incrementValueBlock];
    XCTAssertEqual(testValue, 1,
                   @"The block should have synchronously incremented the value");
}

@end
