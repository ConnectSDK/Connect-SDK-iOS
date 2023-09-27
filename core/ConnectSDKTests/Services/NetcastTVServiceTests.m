//
//  NetcastTVServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/24/15.
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

#import "NetcastTVService_Private.h"
#import "CTXMLReader.h"
#import "DiscoveryManager.h"
#import "NSInvocation+ObjectGetter.h"
#import "XCTestCase+Common.h"

static NSString *const kClientCode = @"nop";

/// Tests for the @c NetcastTVService class.
@interface NetcastTVServiceTests : XCTestCase

@property (nonatomic, strong) id serviceCommandDelegateMock;
@property (nonatomic, strong) NetcastTVService *service;

@end

@implementation NetcastTVServiceTests

- (void)setUp {
    [super setUp];
    self.serviceCommandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    self.service = [NetcastTVService new];
    self.service.serviceCommandDelegate = self.serviceCommandDelegateMock;
}

- (void)tearDown {
    self.service = nil;
    self.serviceCommandDelegateMock = nil;
    [super tearDown];
}

#pragma mark - General Tests

- (void)testInstanceShouldHaveSubtitleSRTCapabilityWithPairingLevelOn {
    [self checkInstanceShouldHaveSubtitleSRTCapabilityWithPairingLevel:DeviceServicePairingLevelOn];
}

- (void)testInstanceShouldHaveSubtitleSRTCapabilityWithPairingLevelOff {
    [self checkInstanceShouldHaveSubtitleSRTCapabilityWithPairingLevel:DeviceServicePairingLevelOff];
}

#pragma mark - Request Generation Tests

/// Tests that @c -sendText:success:failure: creates a proper and valid
/// TextEdited XML request.
- (void)testSendTextShouldCreateProperRequest {
    // Arrange
    NSString *commandName = @"TextEdited";
    static NSString *const defaultText = @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…";

    XCTestExpectation *commandIsSent = [self expectationWithDescription:
                                        [NSString stringWithFormat:@"%@ command is sent", commandName]];

    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                                withPayload:OCMOCK_NOTNIL
                                                      toURL:OCMOCK_ANY]) andDo:^(NSInvocation *inv) {
        NSString *xmlString = [inv objectArgumentAtIndex:1];
        XCTAssertNotNil(xmlString, @"XML request not found");

        NSError *error = nil;
        NSDictionary *dict = [CTXMLReader dictionaryForXMLString:xmlString
                                                           error:&error];
        XCTAssertNil(error, @"XML parsing error");
        XCTAssertNotNil(dict, @"Couldn't parse XML");

        NSDictionary *envelope = dict[@"envelope"];
        XCTAssertNotNil(envelope, @"envelope tag must be present");

        NSDictionary *api = envelope[@"api"];
        XCTAssertNotNil(api, @"api tag must be present");
        XCTAssertEqualObjects(api[@"type"], @"event", @"api.type is incorrect");

        XCTAssertEqualObjects([api valueForKeyPath:@"name.text"], commandName, @"api name is incorrect");
        XCTAssertEqualObjects([api valueForKeyPath:@"state.text"], @"Editing", @"api state is incorrect");
        XCTAssertEqualObjects([api valueForKeyPath:@"value.text"], defaultText, @"api value is incorrect");

        [commandIsSent fulfill];
    }];

    // Act
    [self.service sendText:defaultText
                   success:^(id responseObject) {
                       XCTFail(@"success?");
                   } failure:^(NSError *error) {
                       XCTFail(@"fail? %@", error);
                   }];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

/* The setter tests below test different cases of setting various service
 * config objects and whether those throw an exception when some important data
 * from @c NetcastTVServiceConfig would be lost.
 */

#pragma mark - ServiceConfig Setter Tests (Base <=> Netcast)

- (void)testSwitching_Base_To_NetcastWithoutCode_ServiceConfigShouldNotThrowException {
    ServiceConfig *config = [ServiceConfig new];
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:config];

    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_Base_To_NetcastWithCode_ServiceConfigShouldNotThrowException {
    ServiceConfig *config = [ServiceConfig new];
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:config];

    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithoutCode_To_Base_ServiceConfigShouldNotThrowException {
    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:netcastConfig];

    ServiceConfig *config = [ServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = config,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithCode_To_Base_ServiceConfigShouldThrowException {
    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:netcastConfig];

    ServiceConfig *config = [ServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = config,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the code will disappear");
}

#pragma mark - ServiceConfig Setter Tests (Netcast <=> Netcast)

- (void)testSwitching_NetcastWithoutCode_To_NetcastWithoutCode_ServiceConfigShouldNotThrowException {
    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:netcastConfig];

    NetcastTVServiceConfig *netcastConfig2 = [NetcastTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithoutCode_To_NetcastWithCode_ServiceConfigShouldNotThrowException {
    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:netcastConfig];

    NetcastTVServiceConfig *netcastConfig2 = [NetcastTVServiceConfig new];
    netcastConfig2.pairingCode = kClientCode;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithCode_To_NetcastWithCode_ServiceConfigShouldNotThrowException {
    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:netcastConfig];

    NetcastTVServiceConfig *netcastConfig2 = [NetcastTVServiceConfig new];
    netcastConfig2.pairingCode = @"anotherCode";
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithCode_To_NetcastWithoutCode_ServiceConfigShouldThrowException {
    NetcastTVServiceConfig *netcastConfig = [NetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    NetcastTVService *service = [[NetcastTVService alloc] initWithServiceConfig:netcastConfig];

    NetcastTVServiceConfig *netcastConfig2 = [NetcastTVServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = netcastConfig2,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the code will disappear");
}

- (void)testMediaPlayerPriorityShouldReturnHigh {
    XCTAssertEqual([self.service mediaPlayerPriority], CapabilityPriorityLevelHigh,@"media player priority should be CapabilityPriorityLevelHigh");
}

- (void)testMediaControlPriorityShouldReturnHigh {
    XCTAssertEqual([self.service mediaControlPriority], CapabilityPriorityLevelHigh,@"Media control priority should be CapabilityPriorityLevelHigh");
}

- (void)testRewindShouldReturnFailureBlock {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.service rewindWithSuccess:successVerifier
                                               failure:failureVerifier];
     }];
}

- (void)testFastForwardShouldReturnFailureBlock {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
     ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
         [self.service fastForwardWithSuccess:successVerifier
                                 failure:failureVerifier];
     }];
}

- (void)testShouldHaveFollowingCapabilities {
    NSSet *expectedCapabilities = [NSSet setWithObjects:
                                   kMediaPlayerDisplayImage,
                                   kMediaPlayerPlayVideo,
                                   kMediaPlayerPlayAudio,
                                   kMediaPlayerClose,
                                   kMediaPlayerMetaDataTitle,
                                   kMediaPlayerMetaDataDescription,
                                   kMediaPlayerMetaDataThumbnail,
                                   kMediaPlayerMetaDataMimeType,
                                   kMediaPlayerSubtitleSRT,
                                   kMediaControlPlay,
                                   kMediaControlPause,
                                   kMediaControlStop,
                                   kLauncherYouTube,
                                   kLauncherYouTubeParams,
                                   nil];
    NSSet *actualCapabilities = [NSSet setWithArray:self.service.capabilities];
    XCTAssertEqualObjects(expectedCapabilities, actualCapabilities,
                          @"Netcast capabilities are incorrect");
}

- (void)testNetcastShouldNotHaveSpecificCapabipilities{
    NSSet *currentCapabilities = [NSSet setWithArray:self.service.capabilities];
    XCTAssertFalse([currentCapabilities containsObject:kMediaControlRewind]);
    XCTAssertFalse([currentCapabilities containsObject:kMediaControlFastForward]);
}

#pragma mark - Helpers

- (void)checkInstanceShouldHaveSubtitleSRTCapabilityWithPairingLevel:(DeviceServicePairingLevel)pairingLevel {
    // the test looks ugly because of the implicit dependency on the
    // singleton DiscoveryManager
    // TODO remove the dependency

    DiscoveryManager *discoveryManager = [DiscoveryManager sharedManager];
    DeviceServicePairingLevel oldPairingLevel = discoveryManager.pairingLevel;

    discoveryManager.pairingLevel = pairingLevel;
    XCTAssertNotEqual([self.service.capabilities indexOfObject:kMediaPlayerSubtitleSRT],
                      NSNotFound);

    discoveryManager.pairingLevel = oldPairingLevel;
}

@end
