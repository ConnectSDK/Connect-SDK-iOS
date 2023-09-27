//
//  AirPlayServiceHTTPTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 4/21/15.
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

#import "AirPlayService.h"
#import "AirPlayServiceHTTP_Private.h"

#import "NSInvocation+ObjectGetter.h"
#import "OCMStubRecorder+XCTestExpectation.h"
#import "XCTestCase+Common.h"

/// Tests for the @c AirPlayServiceHTTP class.
@interface AirPlayServiceHTTPTests : XCTestCase

@property (strong) id /*AirPlayService **/ serviceMock;
@property (strong) AirPlayServiceHTTP *serviceHTTP;
@property (strong) id /*<ServiceCommandDelegate>*/ serviceCommandDelegateMock;

@end

@implementation AirPlayServiceHTTPTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.serviceMock = OCMClassMock([AirPlayService class]);
    self.serviceHTTP = [[AirPlayServiceHTTP alloc]
                        initWithAirPlayService:self.serviceMock];

    self.serviceCommandDelegateMock = OCMStrictProtocolMock(@protocol(ServiceCommandDelegate));
    self.serviceHTTP.serviceCommandDelegate = self.serviceCommandDelegateMock;
}

- (void)tearDown {
    self.serviceCommandDelegateMock = nil;
    self.serviceHTTP = nil;
    self.serviceMock = nil;

    [super tearDown];
}

#pragma mark - Request Tests

- (void)testDisplayImageShouldSendPUTPhotoRequest {
    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock commandURL]) andReturn:
     [NSURL URLWithString:@"http://10.0.0.1:9099/"]];
    [OCMStub([self.serviceMock serviceDescription]) andReturn:serviceDescriptionMock];

    XCTestExpectation *commandIsSent = [self expectationWithDescription:
                                        @"Proper request should be sent"];
    [OCMExpect([self.serviceCommandDelegateMock sendCommand:
                [OCMArg checkWithBlock:^BOOL(ServiceCommand *command) {
        return [@"PUT" isEqualToString:command.HTTPMethod];
    }]
                                                withPayload:OCMOCK_NOTNIL
                                                      toURL:
                [OCMArg checkWithBlock:^BOOL(NSURL *url) {
        return [@"/photo" isEqualToString:url.path];
    }]]) andFulfillExpectation:commandIsSent];

    NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"the-san-francisco-peaks-of-flagstaff-718x544"
                                                        withExtension:@"jpg"];
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:url
                                                 mimeType:@"image/jpg"];
    [self.serviceHTTP displayImageWithMediaInfo:mediaInfo
                                        success:nil
                                        failure:nil];

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
    OCMVerifyAll(self.serviceCommandDelegateMock);
}

#pragma mark - getPlayState Tests

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Paused
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPausedWhenRateIsZero {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePaused
                           forMockResponseInFile:@"airplay_playbackinfo_paused"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Playing
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPlayingWhenRateIsOne {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePlaying
                           forMockResponseInFile:@"airplay_playbackinfo_playing"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Playing
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPlayingWhenRateIsTwo {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePlaying
                           forMockResponseInFile:@"airplay_playbackinfo_ff"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Playing
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPlayingWhenRateIsMinusTwo {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePlaying
                           forMockResponseInFile:@"airplay_playbackinfo_rewind"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Finished
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnFinishedWhenRateIsMissing {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStateFinished
                           forMockResponseInFile:@"airplay_playbackinfo_finished"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: infers the Unknown
/// play state from an empty playback-info response.
- (void)testGetPlayStateShouldReturnUnknownWhenResponseIsEmpty {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStateUnknown
                                 forMockResponse:[NSDictionary dictionary]];
}

#pragma mark - Unsupported Methods Tests

- (void)testGetMediaMetadataShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            [self.serviceHTTP getMediaMetaDataWithSuccess:successVerifier
                                                  failure:failureVerifier];
        }];
}

#pragma mark - Helpers

- (void)checkGetPlayStateShouldReturnPlayState:(MediaControlPlayState)expectedPlayState
                         forMockResponseInFile:(NSString *)responseFilename {
    NSString *responseFile = [[NSBundle bundleForClass:self.class] pathForResource:responseFilename
                                                                            ofType:@"json"];
    NSData *responseData = [NSData dataWithContentsOfFile:responseFile];
    NSError *error;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                             options:0
                                                               error:&error];
    XCTAssertNil(error, @"Couldn't read response");

    [self checkGetPlayStateShouldReturnPlayState:expectedPlayState
                                 forMockResponse:response];
}

- (void)checkGetPlayStateShouldReturnPlayState:(MediaControlPlayState)expectedPlayState
                               forMockResponse:(NSDictionary *)response {
    // Arrange
    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                                withPayload:OCMOCK_ANY
                                                      toURL:OCMOCK_ANY])
     andDo:^(NSInvocation *invocation) {
         ServiceCommand *command = [invocation objectArgumentAtIndex:0];
         XCTAssertNotNil(command, @"Couldn't get the command argument");

         dispatch_async(dispatch_get_main_queue(), ^{
             command.callbackComplete(response);
         });
    }];

    XCTestExpectation *didReceivePlayState = [self expectationWithDescription:
                                              @"received playState"];

    // Act
    [self.serviceHTTP getPlayStateWithSuccess:^(MediaControlPlayState playState) {
        XCTAssertEqual(playState, expectedPlayState,
                       @"playState is incorrect");

        [didReceivePlayState fulfill];
    }
                                      failure:^(NSError *error) {
                                          XCTFail(@"Failure %@", error);
                                      }];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
    OCMVerifyAll(self.serviceCommandDelegateMock);
}

@end
