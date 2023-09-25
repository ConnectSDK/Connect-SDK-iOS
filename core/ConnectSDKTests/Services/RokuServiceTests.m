//
//  RokuServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-16.
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

#import "RokuService_Private.h"

#import "ConnectError.h"

#import "NSInvocation+ObjectGetter.h"
#import "XCTestCase+Common.h"

@interface RokuServiceTests : XCTestCase

@property (nonatomic, strong) RokuService *service;
@property (nonatomic, strong) id /*<ServiceCommandDelegate>*/ serviceCommandDelegateMock;

@end

@implementation RokuServiceTests

- (void)setUp {
    [super setUp];

    self.service = [RokuService new];
    self.serviceCommandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    self.service.serviceCommandDelegate = self.serviceCommandDelegateMock;
}

#pragma mark - Request Tests

- (void)testPlayVideoShouldNotSendEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *videoInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"video/mp4"];
    [self checkPlayMediaBlockShouldNotSendEventURL:^{
        [self.service playMediaWithMediaInfo:videoInfo
                                  shouldLoop:NO
                                     success:nil
                                     failure:nil];
    }];
}

- (void)testPlayAudioShouldNotSendEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *audioInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"audio/ogg"];
    [self checkPlayMediaBlockShouldNotSendEventURL:^{
        [self.service playMediaWithMediaInfo:audioInfo
                                  shouldLoop:NO
                                     success:nil
                                     failure:nil];
    }];
}

- (void)testDisplayImageShouldNotSendEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *imageInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"image/png"];
    [self checkPlayMediaBlockShouldNotSendEventURL:^{
        [self.service displayImageWithMediaInfo:imageInfo
                                        success:nil
                                        failure:nil];
    }];
}

#pragma mark - GetAppList Response Tests

- (void)testGetAppListShouldAcceptMultipleApps {
    NSString *appsXML = @"<apps><app id=\"X\" type=\"menu\" version=\"0.1\">The App</app><app id=\"Y\" type=\"menu\" version=\"1.1\">YApp</app></apps>";
    AppInfo *app0 = [AppInfo appInfoForId:@"X"]; app0.name = @"The App";
    AppInfo *app1 = [AppInfo appInfoForId:@"Y"]; app1.name = @"YApp";
    [self checkGetAppListShouldReturnApps:@[app0, app1] forXMLString:appsXML];
}

- (void)testGetAppListShouldAcceptOneApp {
    NSString *appsXML = @"<apps><app id=\"X\" type=\"menu\" version=\"0.1\">The App</app></apps>";
    AppInfo *app = [AppInfo appInfoForId:@"X"]; app.name = @"The App";
    [self checkGetAppListShouldReturnApps:@[app] forXMLString:appsXML];
}

- (void)testGetAppListShouldAcceptZeroApps {
    NSString *appsXML = @"<apps></apps>";
    [self checkGetAppListShouldReturnApps:@[] forXMLString:appsXML];
}

- (void)testGetAppListWrongXMLShouldReturnExmptyList {
    NSString *appsXML = @"<noappshere />";
    [self checkGetAppListShouldReturnApps:@[] forXMLString:appsXML];
}

- (void)testGetAppListInvalidXMLShouldCallFailure {
    NSString *appsXML = @"&oops;";
    [self checkGetAppListShouldReturnApps:nil
                          orErrorWithCode:ConnectStatusCodeTvError
                             forXMLString:appsXML];
}

- (void)testGetAppListNilXMLShouldCallFailure {
    [self checkGetAppListShouldReturnApps:nil
                          orErrorWithCode:ConnectStatusCodeTvError
                             forXMLString:nil];
}

#pragma mark - Unsupported Methods Tests

- (void)testGetDurationShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            [self.service getDurationWithSuccess:^(NSTimeInterval _) {
                    successVerifier(nil);
                }
                                         failure:failureVerifier];
        }];
}

- (void)testGetMediaMetadataShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            [self.service getMediaMetaDataWithSuccess:successVerifier
                                              failure:failureVerifier];
        }];
}

#pragma mark - Helpers

- (void)checkPlayMediaBlockShouldNotSendEventURL:(void (^)())testBlock {
    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock commandURL]) andReturn:[NSURL URLWithString:@"http://42"]];
    self.service.serviceDescription = serviceDescriptionMock;

    XCTestExpectation *commandSentExpectation = [self expectationWithDescription:@"command is sent"];

    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                                withPayload:OCMOCK_ANY
                                                      toURL:OCMOCK_NOTNIL]) andDo:^(NSInvocation *inv) {
        NSURL *url = [inv objectArgumentAtIndex:2];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                                 resolvingAgainstBaseURL:NO];
        NSArray *eventURLQueryItems = [components.queryItems filteredArrayUsingPredicate:
                                       [NSPredicate predicateWithFormat:@"%K == %@", @"name", @"h"]];
        XCTAssertEqual(eventURLQueryItems.count, 0,
                       @"The event URL should not be sent in the request");

        [commandSentExpectation fulfill];
    }];

    testBlock();

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}

- (void)checkGetAppListShouldReturnApps:(NSArray *)apps
                           forXMLString:(NSString *)xmlString {
    [self checkGetAppListShouldReturnApps:apps
                          orErrorWithCode:0
                             forXMLString:xmlString];
}

- (void)checkGetAppListShouldReturnApps:(NSArray *)apps
                        orErrorWithCode:(ConnectStatusCode)errorCode
                           forXMLString:(NSString *)xmlString {
    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_ANY
                                                withPayload:OCMOCK_ANY
                                                      toURL:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        ServiceCommand *command = [invocation objectArgumentAtIndex:0];
        command.callbackComplete(xmlString);
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@""];
    [self.service getAppListWithSuccess:^(NSArray *appList) {
            if (apps) {
                XCTAssertEqualObjects(appList, apps);
                [expectation fulfill];
            }
        }
                                failure:^(NSError *error) {
                                    if (!apps) {
                                        XCTAssertEqual(error.code, errorCode);
                                        [expectation fulfill];
                                    }
                                }];

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}

@end
