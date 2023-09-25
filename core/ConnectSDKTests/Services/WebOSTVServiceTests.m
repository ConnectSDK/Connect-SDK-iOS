//
//  WebOSTVServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/25/15.
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

#import "WebOSTVService_Private.h"

#import "DiscoveryManager.h"
#import "DLNAService.h"
#import "SubtitleInfo.h"
#import "WebOSWebAppSession.h"

#import "NSInvocation+ObjectGetter.h"
#import "XCTestCase+Common.h"

static NSString *const kClientKey = @"clientKey";

static NSString *const kRecentWebOSVersion = @"5.0.0";
static NSString *const kLegacyWebOSVersion = @"4.0.0";

/// Tests for the @c WebOSTVService class.
@interface WebOSTVServiceTests : XCTestCase

@end

@implementation WebOSTVServiceTests

#define CAPTEST(capability, version, pairingLevel, usingDLNA, shouldHave) ({\
    [self checkShouldHave:shouldHave \
       subtitleCapability:capability \
               forVersion:version \
         withPairingLevel:pairingLevel \
             andUsingDLNA:usingDLNA]; \
})

/* Truth table for the capabilities:
 * Version | Pairing | DLNA || VTT | SRT
 * -------------------------------------
 *   nil   |   off   |  NO  || YES |  NO
 *   nil   |   off   | YES  || YES |  NO
 *   nil   |    on   |  NO  || YES |  NO
 *   nil   |    on   | YES  || YES |  NO
 *  4.0.0  |   off   |  NO  ||  NO |  NO
 *  4.0.0  |   off   | YES  ||  NO | YES
 *  4.0.0  |    on   |  NO  ||  NO |  NO
 *  4.0.0  |    on   | YES  ||  NO | YES
 *  5.0.0  |   off   |  NO  || YES |  NO
 *  5.0.0  |   off   | YES  || YES |  NO
 *  5.0.0  |    on   |  NO  || YES |  NO
 *  5.0.0  |    on   | YES  || YES |  NO
 *
 * — If only XCTest supported parameterized tests…
 */

#pragma mark - VTT Subtitles Capabilities Tests

- (void)testShouldHaveVTTCapabilityForMissingVersionWithPairingLevelOffWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, nil, DeviceServicePairingLevelOff, NO, YES);
}

- (void)testShouldHaveVTTCapabilityForMissingVersionWithPairingLevelOffWithDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, nil, DeviceServicePairingLevelOff, YES, YES);
}

- (void)testShouldHaveVTTCapabilityForMissingVersionWithPairingLevelOnWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, nil, DeviceServicePairingLevelOn, NO, YES);
}

- (void)testShouldHaveVTTCapabilityForMissingVersionWithPairingLevelOnWithDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, nil, DeviceServicePairingLevelOn, YES, YES);
}

- (void)testShouldNotHaveVTTCapabilityForLegacyVersionWithPairingLevelOffWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kLegacyWebOSVersion, DeviceServicePairingLevelOff, NO, NO);
}

- (void)testShouldNotHaveVTTCapabilityForLegacyVersionWithPairingLevelOffWithDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kLegacyWebOSVersion, DeviceServicePairingLevelOff, YES, NO);
}

- (void)testShouldNotHaveVTTCapabilityForLegacyVersionWithPairingLevelOnWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kLegacyWebOSVersion, DeviceServicePairingLevelOn, NO, NO);
}

- (void)testShouldNotHaveVTTCapabilityForLegacyVersionWithPairingLevelOnWithDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kLegacyWebOSVersion, DeviceServicePairingLevelOn, YES, NO);
}

- (void)testShouldHaveVTTCapabilityForRecentVersionWithPairingLevelOffWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kRecentWebOSVersion, DeviceServicePairingLevelOff, NO, YES);
}

- (void)testShouldHaveVTTCapabilityForRecentVersionWithPairingLevelOffWithDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kRecentWebOSVersion, DeviceServicePairingLevelOff, YES, YES);
}

- (void)testShouldHaveVTTCapabilityForRecentVersionWithPairingLevelOnWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kRecentWebOSVersion, DeviceServicePairingLevelOn, NO, YES);
}

- (void)testShouldHaveVTTCapabilityForRecentVersionWithPairingLevelOnWithDLNA {
    CAPTEST(kMediaPlayerSubtitleWebVTT, kRecentWebOSVersion, DeviceServicePairingLevelOn, YES, YES);
}

#pragma mark - SRT Subtitles Capabilities Tests

- (void)testShouldNotHaveSRTCapabilityForMissingVersionWithPairingLevelOffWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, nil, DeviceServicePairingLevelOff, NO, NO);
}

- (void)testShouldNotHaveSRTCapabilityForMissingVersionWithPairingLevelOffWithDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, nil, DeviceServicePairingLevelOff, YES, NO);
}

- (void)testShouldNotHaveSRTCapabilityForMissingVersionWithPairingLevelOnWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, nil, DeviceServicePairingLevelOn, NO, NO);
}

- (void)testShouldNotHaveSRTCapabilityForMissingVersionWithPairingLevelOnWithDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, nil, DeviceServicePairingLevelOn, YES, NO);
}

- (void)testShouldNotHaveSRTCapabilityForLegacyVersionWithPairingLevelOffWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kLegacyWebOSVersion, DeviceServicePairingLevelOff, NO, NO);
}

- (void)testShouldHaveSRTCapabilityForLegacyVersionWithPairingLevelOffWithDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kLegacyWebOSVersion, DeviceServicePairingLevelOff, YES, YES);
}

- (void)testShouldNotHaveSRTCapabilityForLegacyVersionWithPairingLevelOnWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kLegacyWebOSVersion, DeviceServicePairingLevelOn, NO, NO);
}

- (void)testShouldHaveSRTCapabilityForLegacyVersionWithPairingLevelOnWithDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kLegacyWebOSVersion, DeviceServicePairingLevelOn, YES, YES);
}

- (void)testShouldNotHaveSRTCapabilityForRecentVersionWithPairingLevelOffWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kRecentWebOSVersion, DeviceServicePairingLevelOff, NO, NO);
}

- (void)testShouldNotHaveSRTCapabilityForRecentVersionWithPairingLevelOffWithDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kRecentWebOSVersion, DeviceServicePairingLevelOff, YES, NO);
}

- (void)testShouldNotHaveSRTCapabilityForRecentVersionWithPairingLevelOnWithoutDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kRecentWebOSVersion, DeviceServicePairingLevelOn, NO, NO);
}

- (void)testShouldNotHaveSRTCapabilityForRecentVersionWithPairingLevelOnWithDLNA {
    CAPTEST(kMediaPlayerSubtitleSRT, kRecentWebOSVersion, DeviceServicePairingLevelOn, YES, NO);
}

#pragma mark - Subtitles Support Tests

- (void)testPlayMediaWithSubtitlesShouldCallWebOSWebAppSessionForRecentVersion {
    WebOSTVService *service = OCMPartialMock([WebOSTVService new]);
    [self mockWebOSVersion:kRecentWebOSVersion onService:service];

    id webAppSessionMock = OCMClassMock([WebOSWebAppSession class]);
    OCMStub([service createWebAppSessionWithLaunchSession:OCMOCK_ANY
                                               andService:OCMOCK_ANY]).andReturn(webAppSessionMock);
    [OCMStub([webAppSessionMock joinWithSuccess:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        SuccessBlock joinSuccess = [invocation objectArgumentAtIndex:0];
        joinSuccess(webAppSessionMock);
    }];
    OCMStub([webAppSessionMock mediaPlayer]).andReturn(webAppSessionMock);

    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];
    MediaPlayerSuccessBlock success = ^(MediaLaunchObject *mediaLaunchObject) {};
    FailureBlock failure = ^(NSError *error) {};

    OCMExpect([webAppSessionMock playMediaWithMediaInfo:mediaInfo
                                             shouldLoop:NO
                                                success:success
                                                failure:failure]);
    [service playMediaWithMediaInfo:mediaInfo
                         shouldLoop:NO
                            success:success
                            failure:failure];

    OCMVerifyAll(webAppSessionMock);
}

- (void)testPlayMediaWithSubtitlesShouldCallDLNAServiceForLegacyVersion {
    WebOSTVService *service = OCMPartialMock([WebOSTVService new]);
    [self mockWebOSVersion:kLegacyWebOSVersion onService:service];

    id dlnaServiceMock = OCMClassMock([DLNAService class]);
    OCMStub([service dlnaService]).andReturn(dlnaServiceMock);
    OCMStub([dlnaServiceMock mediaPlayer]).andReturn(dlnaServiceMock);

    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];
    MediaPlayerSuccessBlock success = ^(MediaLaunchObject *mediaLaunchObject) {};
    FailureBlock failure = ^(NSError *error) {};

    OCMExpect([dlnaServiceMock playMediaWithMediaInfo:mediaInfo
                                           shouldLoop:NO
                                              success:success
                                              failure:failure]);
    [service playMediaWithMediaInfo:mediaInfo
                         shouldLoop:NO
                            success:success
                            failure:failure];

    OCMVerifyAll(dlnaServiceMock);
}

- (void)testPlayMediaWithSubtitlesShouldSendMediaViewerOpenCommandForLegacyVersionWithoutDLNA {
    WebOSTVService *service = OCMPartialMock([WebOSTVService new]);
    [self mockWebOSVersion:kLegacyWebOSVersion onService:service];

    OCMStub([service dlnaService]).andReturn(nil);

    MediaInfo *mediaInfo = [self mediaInfoWithSubtitle];

    id serviceCommandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    service.serviceCommandDelegate = serviceCommandDelegateMock;
    OCMExpect([serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                          withPayload:[OCMArg checkWithBlock:(^BOOL(NSDictionary *payload) {
                                              NSDictionary *expectedPayload = @{
                                                  @"target": mediaInfo.url.absoluteString,
                                                  @"mimeType": mediaInfo.mimeType,
                                                  @"loop": @"false",
                                                  @"title": @"",
                                                  @"description": @"",
                                                  @"iconSrc": @"",
                                              };
                                              XCTAssertEqualObjects(expectedPayload, payload);
                                              return YES;
                                          })]
                                                toURL:[OCMArg checkWithBlock:^BOOL(NSURL *url) {
                                                    XCTAssertEqualObjects(@"ssap://media.viewer/open",
                                                                          url.absoluteString);
                                                    return YES;
                                                }]]);

    [service playMediaWithMediaInfo:mediaInfo
                         shouldLoop:NO
                            success:nil
                            failure:nil];

    OCMVerifyAll(serviceCommandDelegateMock);
}

#pragma mark - Unsupported Methods Tests

- (void)testGetDurationShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            WebOSTVService *service = [WebOSTVService new];
            [service getDurationWithSuccess:^(NSTimeInterval _) {
                    successVerifier(nil);
                }
                                    failure:failureVerifier];
        }];
}

- (void)testGetMediaMetadataShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            WebOSTVService *service = [WebOSTVService new];
            [service getMediaMetaDataWithSuccess:successVerifier
                                         failure:failureVerifier];
        }];
}

#pragma mark - ServiceConfig Setter Tests (Base <=> WebOS)

/* The setter tests below test different cases of setting various service
 * config objects and whether those throw an exception when a client key from
 * @c WebOSTVServiceConfig would be lost.
 */

- (void)testSwitching_Base_To_WebOSWithoutKey_ServiceConfigShouldNotThrowException {
    ServiceConfig *config = [ServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:config];

    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_Base_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    ServiceConfig *config = [ServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:config];

    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithoutKey_To_Base_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    ServiceConfig *config = [ServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = config,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_Base_ServiceConfigShouldThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    ServiceConfig *config = [ServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = config,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the key will disappear");
}

#pragma mark - ServiceConfig Setter Tests (WebOS <=> WebOS)

- (void)testSwitching_WebOSWithoutKey_To_WebOSWithoutKey_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithoutKey_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    webosConfig2.clientKey = kClientKey;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    webosConfig2.clientKey = @"anotherKey";
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_WebOSWithoutKey_ServiceConfigShouldThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = webosConfig2,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the key will disappear");
}

#pragma mark - Helpers

- (void)checkShouldHave:(BOOL)shouldHave
     subtitleCapability:(NSString *)subtitleCapability
             forVersion:(NSString *)version
       withPairingLevel:(DeviceServicePairingLevel)pairingLevel
           andUsingDLNA:(BOOL)usingDLNA {
    DiscoveryManager *discoveryManager = [DiscoveryManager sharedManager];
    DeviceServicePairingLevel oldPairingLevel = discoveryManager.pairingLevel;
    discoveryManager.pairingLevel = pairingLevel;

    WebOSTVService *service = OCMPartialMock([WebOSTVService new]);
    id dlnaServiceStub = usingDLNA ? OCMClassMock([DLNAService class]) : nil;
    OCMStub([service dlnaService]).andReturn(dlnaServiceStub);
    [self mockWebOSVersion:version onService:service];

    XCTAssertEqual([service.capabilities containsObject:subtitleCapability],
                   shouldHave);

    discoveryManager.pairingLevel = oldPairingLevel;
}

- (void)mockWebOSVersion:(NSString *)version
               onService:(WebOSTVService *)service {
    if (version) {
        id serviceDescriptionStub = OCMClassMock([ServiceDescription class]);
        NSDictionary *headers = @{
            @"Server": [NSString stringWithFormat:@"A/%@ x", version]};
        OCMStub([serviceDescriptionStub locationResponseHeaders]).andReturn(
            headers);
        OCMStub([(ServiceDescription *) serviceDescriptionStub version]).andReturn(
            version);
        service.serviceDescription = serviceDescriptionStub;
    }
}

- (MediaInfo *)mediaInfoWithSubtitle {
    NSURL *subtitleURL = [NSURL URLWithString:@"http://example.com/"];
    SubtitleInfo *subtitleInfo = [SubtitleInfo infoWithURL:subtitleURL
                                                  andBlock:^(SubtitleInfoBuilder *builder) {
                                                      builder.language = @"en";
                                                      builder.label = @"test";
                                                  }];
    MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:[NSURL URLWithString:@"http://url"]
                                                 mimeType:@"video/mp4"];
    mediaInfo.subtitleInfo = subtitleInfo;

    return mediaInfo;
}

@end
