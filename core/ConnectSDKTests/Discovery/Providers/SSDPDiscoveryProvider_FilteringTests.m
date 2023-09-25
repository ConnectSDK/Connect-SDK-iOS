//
//  SSDPDiscoveryProvider_FilteringTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/15/15.
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

#import <OHHTTPStubs/OHHTTPStubs.h>

#import "SSDPDiscoveryProvider_Private.h"
#import "SSDPSocketListener.h"

#import "DIALService.h"
#import "DLNAService.h"
#import "NetcastTVService.h"
#import "RokuService.h"
#import "WebOSTVService.h"

static const NSUInteger kSSDPMulticastTCPPort = 1900;


/// Tests for the @c SSDPDiscoveryProvider 's discovery and filtering features.
@interface SSDPDiscoveryProvider_FilteringTests : XCTestCase

@end

@implementation SSDPDiscoveryProvider_FilteringTests

#pragma mark - DLNA/Netcast Services Filtering Tests

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description with DLNA filter only and accepts the service.
- (void)testShouldFindDLNAService_Sonos {
    [self checkShouldFindDevice:@"sonos"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description (without the root serviceList) with DLNA filter only and accepts
/// the service.
- (void)testShouldFindDLNAService_SonosBased_NoRootServices {
    [self checkShouldFindDevice:@"sonos_no_root_services"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Xbox's XML device
/// description with DLNA filter only and accepts the service.
- (void)testShouldFindDLNAService_Xbox {
    [self checkShouldFindDevice:@"xbox"
       withExpectedFriendlyName:@"XboxOne"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description with Netcast and DLNA filters (in this order!) and accepts the
/// service.
- (void)testShouldFindDLNAServiceConsideringNetcast_Sonos {
    // the Netcast, then DLNA order is crucial here, since the Netcast service
    // doesn't have any required services, thus short-circuiting the check for
    // all DLNA devices (both services have the same filter)
    [self checkShouldFindDevice:@"sonos"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description (without the root serviceList) with Netcast and DLNA filters (in
/// this order!) and accepts the service.
- (void)testShouldFindDLNAServiceConsideringNetcast_SonosBased_NoRootServices {
    [self checkShouldFindDevice:@"sonos_no_root_services"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Xbox's XML device
/// description with Netcast and DLNA filters (in this order!) and accepts the
/// service.
- (void)testShouldFindDLNAServiceConsideringNetcast_Xbox {
    [self checkShouldFindDevice:@"xbox"
       withExpectedFriendlyName:@"XboxOne"
        usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

- (void)testShouldNotFindDLNAServiceWithoutRequiredServices {
    [self checkShouldNotFindDevice:@"dlna_no_required_services"
           usingDiscoveryProviders:@[[DLNAService class]]];
}

- (void)testShouldNotFindDLNAServiceConsideringNetcastWithoutRequiredServices {
    [self checkShouldNotFindDevice:@"dlna_no_required_services"
           usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

- (void)testShouldNotFindDLNAServiceWithoutRequiredServicesInRoot {
    [self checkShouldNotFindDevice:@"dlna_root_no_required_services"
           usingDiscoveryProviders:@[[DLNAService class]]];
}

- (void)testShouldNotFindDLNAServiceConsideringNetcastWithoutRequiredServicesInRoot {
    [self checkShouldNotFindDevice:@"dlna_root_no_required_services"
           usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

- (void)testShouldFindSamsungTVWithDLNAService {
    [self checkShouldFindDevice:@"samsung_tv_dlna"
       withExpectedFriendlyName:@"Samsung LED"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

- (void)testShouldFindWebosWithDLNAService {
    [self checkShouldFindDevice:@"webos_minor_dlna"
       withExpectedFriendlyName:@"MR"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

- (void)testShouldFindLGSpeakerWithDLNAService {
    [self checkShouldFindDevice:@"lg_speaker"
       withExpectedFriendlyName:@"Music Flow H3"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

#pragma mark - DIAL Service Filtering Tests

- (void)testShouldFindFireTVWithDIALService {
    [self checkShouldFindDevice:@"firetv"
       withExpectedFriendlyName:@"Fire TV"
        usingDiscoveryProviders:@[[DIALService class]]];
}

- (void)testShouldFindChromecastWithDIALService {
    [self checkShouldFindDevice:@"chromecast"
       withExpectedFriendlyName:@"Chromecast"
        usingDiscoveryProviders:@[[DIALService class]]];
}

- (void)testShouldFindRokuWithDIALService {
    [self checkShouldFindDevice:@"roku2"
       withExpectedFriendlyName:@"Roku2"
        usingDiscoveryProviders:@[[DIALService class]]];
}

- (void)testShouldFindSamsungTVWithDIALService {
    [self checkShouldFindDevice:@"samsung_tv"
       withExpectedFriendlyName:@"Samsung LED"
        usingDiscoveryProviders:@[[DIALService class]]];
}

- (void)testShouldFindXboxWithDIALService {
    [self checkShouldFindDevice:@"xbox_dial"
       withExpectedFriendlyName:@"XboxOne"
        usingDiscoveryProviders:@[[DIALService class]]];
}

- (void)testShouldFindWebosWithDIALService {
    [self checkShouldFindDevice:@"webos_minor"
       withExpectedFriendlyName:@"MR"
        usingDiscoveryProviders:@[[DIALService class]]];
}

#pragma mark - Roku Service Filtering Tests

- (void)testShouldFindRokuWithRokuService {
    [self checkShouldFindDevice:@"roku2"
       withExpectedFriendlyName:@"Roku2"
        usingDiscoveryProviders:@[[RokuService class]]];
}

#pragma mark - WebOS Service Filtering Tests

- (void)testShouldFindWebOSWithWebOSService {
    [self checkShouldFindDevice:@"webos_minor_webos"
       withExpectedFriendlyName:@"MR"
        usingDiscoveryProviders:@[[WebOSTVService class]]];
}

#pragma mark - Helpers

- (void)checkShouldFindDevice:(NSString *)device
     withExpectedFriendlyName:(NSString *)friendlyName
      usingDiscoveryProviders:(NSArray *)discoveryProviders {
    // Arrange
    SSDPDiscoveryProvider *provider = [SSDPDiscoveryProvider new];
    [discoveryProviders enumerateObjectsUsingBlock:^(Class class, NSUInteger idx, BOOL *stop) {
        [provider addDeviceFilter:[class discoveryParameters]];
    }];

    id searchSocketMock = OCMClassMock([SSDPSocketListener class]);
    provider.searchSocket = searchSocketMock;

    NSString *serviceType = [discoveryProviders.firstObject discoveryParameters][@"ssdp"][@"filter"];
    OCMStub([searchSocketMock sendData:OCMOCK_NOTNIL
                             toAddress:OCMOCK_NOTNIL
                               andPort:kSSDPMulticastTCPPort]).andDo((^(NSInvocation *invocation) {
        NSString *searchResponse = [NSString stringWithFormat:
                                    @"HTTP/1.1 200 OK\r\n"
                                    @"CACHE-CONTROL: max-age=1800\r\n"
                                    @"Date: Thu, 01 Jan 1970 04:04:04 GMT\r\n"
                                    @"EXT:\r\n"
                                    @"LOCATION: http://127.1/\r\n"
                                    @"SERVER: Linux/4.2 UPnP/1.1 MagicDevice/1.0\r\n"
                                    @"ST: %@\r\n"
                                    @"USN: uuid:f21e800a-1000-ab08-8e5a-76f4fcb5e772::urn:schemas-upnp-org:device:thing:1\r\n"
                                    @"Content-Length: 0\r\n"
                                    @"\r\n",
                                    // NOTE: be careful with setting the service type from
                                    // the discovery parameters. properly, it should be the
                                    // value from the real device
                                    serviceType];
        NSData *searchResponseData = [searchResponse dataUsingEncoding:NSUTF8StringEncoding];

        [provider socket:searchSocketMock
          didReceiveData:searchResponseData
             fromAddress:@"127.2"];
    }));

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *filename = OHPathForFileInBundle(([NSString stringWithFormat:@"ssdp_device_description_%@.xml", device]), nil);
        return [OHHTTPStubsResponse responseWithFileAtPath:filename
                                                statusCode:200
                                                   headers:nil];
    }];

    id discoveryProviderDelegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    provider.delegate = discoveryProviderDelegateMock;

    if (friendlyName) {
        XCTestExpectation *didFindServiceExpectation = [self expectationWithDescription:@"Did find device with given service"];

        OCMExpect([discoveryProviderDelegateMock discoveryProvider:[OCMArg isEqual:provider]
                                                    didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
            XCTAssertEqualObjects(service.friendlyName, friendlyName,
                                  @"The device's friendlyName doesn't match");
            [didFindServiceExpectation fulfill];
            return YES;
        }]]);

        // Act
        [provider startDiscovery];

        // Assert
        [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                     handler:^(NSError *error) {
                                         XCTAssertNil(error);
                                         OCMVerifyAll(discoveryProviderDelegateMock);
                                     }];
    } else {
        // I tried to use [mock reject] and strict mocks at first, but they
        // throw an `NSInternalInconsistencyException` that terminates the test
        // process. It's impossible to catch, `XCTAssertNoThrow()` and
        // `@try/@catch` don't work. So this is a workaround to make sure the
        // method isn't called without throwing an exception.
        // /* yeah, Xcode and iOS SDK don't seem to be test-friendly :( */
        OCMStub([discoveryProviderDelegateMock discoveryProvider:OCMOCK_ANY
                                                  didFindService:OCMOCK_ANY]).andDo(^(NSInvocation *_) {
            XCTFail(@"discoveryProvider:didFindService: must not be called");
        });

        // Act
        [provider startDiscovery];
        [self runRunLoopForInterval:kDefaultAsyncTestTimeout];

        // Assert
        OCMVerifyAll(discoveryProviderDelegateMock);
    }
}

- (void)checkShouldNotFindDevice:(NSString *)device
         usingDiscoveryProviders:(NSArray *)discoveryProviders {
    [self checkShouldFindDevice:device
       withExpectedFriendlyName:nil
        usingDiscoveryProviders:discoveryProviders];
}

- (void)runRunLoopForInterval:(CGFloat)interval {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutDate];
    }
}

@end
