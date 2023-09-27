//
//  AirPlayServiceHTTPKeepAliveTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 12/17/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
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



#import "AirPlayServiceHTTPKeepAlive.h"
#import "ServiceCommandDelegate.h"

static const CGFloat kDefaultKeepAliveInterval = 0.1f;


/// Tests for the @c AirPlayServiceHTTPKeepAlive class.
@interface AirPlayServiceHTTPKeepAliveTests : XCTestCase

@property (nonatomic, strong) AirPlayServiceHTTPKeepAlive *keepAlive;
@property (nonatomic, strong) id commandDelegateMock;

@end

@implementation AirPlayServiceHTTPKeepAliveTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.commandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    self.keepAlive = [[AirPlayServiceHTTPKeepAlive alloc] initWithInterval:kDefaultKeepAliveInterval
                                                        andCommandDelegate:self.commandDelegateMock];
    self.keepAlive.commandURL = [NSURL URLWithString:@"http://example.com/"];
}

- (void)tearDown {
    self.keepAlive = nil;
    self.commandDelegateMock = nil;

    [super tearDown];
}

#pragma mark - Keep-Alive timer tests

/// Tests that a newly created keep-alive object should not start automatically.
- (void)testCreatedKeepAliveShouldNotBeStarted {
    // Arrange
    [[self.commandDelegateMock reject] sendCommand:OCMOCK_ANY
                                       withPayload:OCMOCK_ANY
                                             toURL:OCMOCK_ANY];
    AirPlayServiceHTTPKeepAlive *keepAlive = [[AirPlayServiceHTTPKeepAlive alloc] initWithInterval:kDefaultKeepAliveInterval
                                                                                andCommandDelegate:self.commandDelegateMock];
    keepAlive.commandURL = [NSURL URLWithString:@"http://example.com/"];

    // Act
    [self runRunLoopForInterval:kDefaultAsyncTestTimeout];

    // Assert
    OCMVerifyAll(self.commandDelegateMock);
}

/// Tests that -startTimer makes the object send keep-alive commands.
- (void)testStartTimerShouldSendRequest {
    // Arrange
    XCTestExpectation *sendKeepAliveExpectation = [self expectationWithDescription:@"Keep-alive is sent"];
    OCMStub([self.commandDelegateMock sendCommand:[OCMArg isNotNil]
                                      withPayload:OCMOCK_ANY
                                            toURL:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.keepAlive stopTimer];
        [sendKeepAliveExpectation fulfill];
    });

    // Act
    [self.keepAlive startTimer];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.commandDelegateMock);
                                 }];
}

/// Tests that -startTimer makes the object send keep-alive requests perodically.
- (void)testStartTimerShouldSendRequests {
    // Arrange
    __block NSUInteger invocationCount = 0;
    OCMStub([self.commandDelegateMock sendCommand:[OCMArg isNotNil]
                                      withPayload:OCMOCK_ANY
                                            toURL:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        ++invocationCount;
    });

    // Act
    [self.keepAlive startTimer];

    // Assert
    [self runRunLoopForInterval:kDefaultAsyncTestTimeout];
    [self.keepAlive stopTimer];

    const NSUInteger expectedInvocationCount = (NSUInteger)ceil(kDefaultAsyncTestTimeout / kDefaultKeepAliveInterval);
    XCTAssertGreaterThanOrEqual(invocationCount,
                                expectedInvocationCount - 1,
                                @"The request wasn't sent the expected number of times");
}

/// Tests that -stopTimer after starting it stops the keep-alive requests.
- (void)testStopTimerShouldStopSendingRequests {
    // Arrange
    id commandDelegateMock2 = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    [[commandDelegateMock2 reject] sendCommand:OCMOCK_ANY
                                   withPayload:OCMOCK_ANY
                                         toURL:OCMOCK_ANY];

    OCMExpect([self.commandDelegateMock sendCommand:[OCMArg isNotNil]
                                        withPayload:OCMOCK_ANY
                                              toURL:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.keepAlive stopTimer];
        // replace the delegate with a fresh mock
        self.keepAlive.commandDelegate = commandDelegateMock2;
    });

    // Act
    [self.keepAlive startTimer];

    // Assert
    [self runRunLoopForInterval:kDefaultAsyncTestTimeout];
    OCMVerifyAll(self.commandDelegateMock);
    OCMVerifyAll(commandDelegateMock2);
}

#pragma mark - Helpers

- (void)runRunLoopForInterval:(CGFloat)interval {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutDate];
    }
}

@end
