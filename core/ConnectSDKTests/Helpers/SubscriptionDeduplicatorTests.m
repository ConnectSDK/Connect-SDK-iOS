//
//  SubscriptionDeduplicatorTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-06-26.
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

#import "SubscriptionDeduplicator.h"

@interface SubscriptionDeduplicatorTests : XCTestCase

@property (nonatomic, strong) SubscriptionDeduplicator *deduplicator;

@end

@implementation SubscriptionDeduplicatorTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];
    self.deduplicator = [SubscriptionDeduplicator new];
}

- (void)tearDown {
    self.deduplicator = nil;
    [super tearDown];
}

#pragma mark - State Tests

- (void)testInstanceShouldBeCreated {
    XCTAssertNotNil(self.deduplicator, @"Empty state instance should be created");
}

- (void)testFirstStateChangeShouldRunBlock {
    __block BOOL blockRun = NO;
    [self.deduplicator runBlock:^{
        blockRun = YES;
    }
             ifStateDidChangeTo:@42];
    XCTAssertTrue(blockRun, @"Block should be run on first state change");
}

- (void)testSameStateChangeShouldNotRunBlock {
    self.deduplicator = [self.deduplicator runBlock:^{} ifStateDidChangeTo:@42];
    __block BOOL blockRun = NO;
    [self.deduplicator runBlock:^{
        blockRun = YES;
    }
            ifStateDidChangeTo:@42];
    XCTAssertFalse(blockRun,
                   @"Block should not be run after the same state change");
}

- (void)testTwoStateChangesShouldRunBlocks {
    __block BOOL firstBlockRun = NO;
    self.deduplicator = [self.deduplicator runBlock:^{
        firstBlockRun = YES;
    }
                                 ifStateDidChangeTo:@42];
    __block BOOL secondBlockRun = NO;
    [self.deduplicator runBlock:^{
        secondBlockRun = YES;
    }
             ifStateDidChangeTo:@"hello"];
    XCTAssertTrue(firstBlockRun && secondBlockRun,
                  @"Both blocks should be run");
}

- (void)testSameStateChangeShouldNotCreateNewInstance {
    self.deduplicator = [self.deduplicator runBlock:^{} ifStateDidChangeTo:@42];
    XCTAssertEqual([self.deduplicator runBlock:^{} ifStateDidChangeTo:@42],
                   self.deduplicator,
                   @"Should return self if state hasn't changed");
}

@end
