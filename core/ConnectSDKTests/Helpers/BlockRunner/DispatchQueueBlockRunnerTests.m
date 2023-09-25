//
//  DispatchQueueBlockRunnerTests.m
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

#import "DispatchQueueBlockRunner.h"

@interface DispatchQueueBlockRunnerTests : XCTestCase

@property (strong) DispatchQueueBlockRunner *runner;
@property (strong) dispatch_queue_t queue;

@end

@implementation DispatchQueueBlockRunnerTests

- (void)setUp {
    [super setUp];

    self.queue = dispatch_queue_create("DispatchQueueBlockRunnerTests.queue",
                                       DISPATCH_QUEUE_SERIAL);
    self.runner = [[DispatchQueueBlockRunner alloc] initWithDispatchQueue:self.queue];
}

- (void)tearDown {
    self.queue = nil;
    self.runner = nil;

    [super tearDown];
}

- (void)testClassShouldImplementBlockRunner {
    XCTAssertTrue([self.runner.class conformsToProtocol:@protocol(BlockRunner)]);
}

- (void)testNilQueueInInitShouldNotBeAccepted {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([[DispatchQueueBlockRunner alloc] initWithDispatchQueue:nil],
                    @"nil queue is not accepted");
#pragma clang diagnostic pop
}

- (void)testDefaultInitShouldNotBeAllowed {
    XCTAssertThrows([DispatchQueueBlockRunner new], @"queue must be specified");
}

- (void)testNilBlockShouldNotBeAccepted {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertThrows([self.runner runBlock:nil], @"nil block is not accepted");
#pragma clang diagnostic pop
}

- (void)ignored_testBlockShouldNotBeRunSynchronously {
    /* NB: this test is ignored for now, because it sometimes fails on CI
     servers, occasionally running the block synchronously in all iterations. */

    /* to verify the block is not called synchronously, it shouldn't increment a
     value, that is checked after scheduling the block. however, GCD doesn't
     promise that the block won't run immediately, which actually happens and
     failed the test very occasionally. now, we run the test thousands of times
     to verify the block is called asynchronously in most cases (>= 80%). */

    NSUInteger failCount = 0;
    static const NSUInteger iterationCount = 10000;
    for (NSUInteger i = 0; i < iterationCount; ++i) {
        __block NSUInteger testValue = 0;
        void(^incrementValueBlock)(void) = ^{
            ++testValue;

            XCTAssertFalse([NSThread isMainThread]);
        };
        [self.runner runBlock:incrementValueBlock];

        NSUInteger isFail = (0 != testValue);
        failCount += isFail;
    }

    XCTAssertLessThan(failCount, (NSUInteger)trunc(iterationCount * 0.2),
                      @"The block should not run synchronously "
                      @"(in more than 20%% of cases)");
}

- (void)testBlockShouldBeRunAsynchronously {
    for (NSUInteger i = 0; i < 10000; ++i) {
        __block NSUInteger testValue = 0;
        void(^incrementValueBlock)(void) = ^{
            ++testValue;
        };

        XCTestExpectation *allBlockAreRun = [self expectationWithDescription:
                                             @"All blocks on the queue are run"];
        // NB: since dispatch_get_current_queue() is deprecated, we have to make
        // assumptions with workarounds
        dispatch_async(self.queue, ^{
            XCTAssertEqual(testValue, 0, @"The block should not have been run yet");
        });
        [self.runner runBlock:incrementValueBlock];
        dispatch_async(self.queue, ^{
            [allBlockAreRun fulfill];
        });

        [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                     handler:^(NSError *error) {
                                         XCTAssertNil(error);
                                     }];
        XCTAssertEqual(testValue, 1, @"The block should have been run already");
    }
}

- (void)testInstancesShouldBeEqualIfQueuesAreEqual {
    DispatchQueueBlockRunner *runner = [[DispatchQueueBlockRunner alloc]
                                        initWithDispatchQueue:self.queue];
    XCTAssertEqualObjects(self.runner, runner,
                          @"The two instances should be equal because they use the same queue");
}

- (void)testHashesShouldBeEqualIfQueuesAreEqual {
    DispatchQueueBlockRunner *runner = [[DispatchQueueBlockRunner alloc]
                                        initWithDispatchQueue:self.queue];
    XCTAssertEqual(self.runner.hash, runner.hash,
                   @"The two instances should have equal hash because they are equal");
}

- (void)testMainDispatchQueueBlockRunnerShouldCreateMainQueueInstance {
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    DispatchQueueBlockRunner *manualMainQueueRunner = [[DispatchQueueBlockRunner alloc]
                                                 initWithDispatchQueue:mainQueue];

    DispatchQueueBlockRunner *convenienceMainQueueRunner = [DispatchQueueBlockRunner mainQueueRunner];
    XCTAssertEqualObjects(manualMainQueueRunner, convenienceMainQueueRunner,
                          @"The mainQueueRunner should return runner with main queue");
}

@end
