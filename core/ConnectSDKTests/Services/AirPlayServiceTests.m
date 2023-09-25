//
//  AirPlayServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-29.
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

#import "AirPlayService_Private.h"

#import "XCTestCase+Common.h"

@interface AirPlayServiceTests : XCTestCase

@end

@implementation AirPlayServiceTests

#pragma mark - Unsupported Methods Tests

- (void)testGetMediaMetadataShouldBeForwardedToHTTPServiceMediaControl {
    AirPlayService *service = OCMPartialMock([AirPlayService new]);

    id /*AirPlayServiceHTTP **/ httpServiceStub = OCMClassMock([AirPlayServiceHTTP class]);
    OCMStub([service createHTTPService]).andReturn(httpServiceStub);

    id /*<MediaControl>*/ mediaControlMock = OCMProtocolMock(@protocol(MediaControl));
    OCMStub([httpServiceStub mediaControl]).andReturn(mediaControlMock);

    SuccessBlock successBlock = ^(id _) {};
    FailureBlock failureBlock = ^(NSError *_) {};
    OCMExpect([mediaControlMock getMediaMetaDataWithSuccess:successBlock
                                                    failure:failureBlock]);

    [service getMediaMetaDataWithSuccess:successBlock
                                 failure:failureBlock];

    OCMVerifyAll(mediaControlMock);
}

@end
