//
//  SSDPDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/11/14.
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


#import <OHHTTPStubs/OHHTTPStubs.h>

#import "SSDPDiscoveryProvider_Private.h"
#import "SSDPSocketListener.h"
#import "ServiceDescription.h"

static NSString *const kSSDPMulticastIPAddress = @"239.255.255.250";
static const NSUInteger kSSDPMulticastTCPPort = 1900;

static NSString *const kKeySSDP = @"ssdp";
static NSString *const kKeyFilter = @"filter";
static NSString *const kKeyServiceID = @"serviceId";

static inline NSString *httpHeaderValue(CFHTTPMessageRef msg, NSString *header) {
    return CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(msg, (__bridge CFStringRef)header));
}


/// Tests for the SSDPDiscoveryProvider class.
/// In some tests, the SSDPSocketListener class is mocked to verify the output
/// data or provide some input data. Also, HTTP requests/responses are mocked
/// to fake device description data.
@interface SSDPDiscoveryProviderTests : XCTestCase

@property (nonatomic, strong) SSDPDiscoveryProvider *provider;

@end

@implementation SSDPDiscoveryProviderTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.provider = [SSDPDiscoveryProvider new];
}

- (void)tearDown {
    self.provider = nil;

    [OHHTTPStubs removeAllStubs];

    [super tearDown];
}

#pragma mark - General tests

/// Tests that a new provider is not running by default.
- (void)testShouldNotBeRunningAfterCreation {
    XCTAssertFalse(self.provider.isRunning, @"The provider must not be running after creation");
}

#pragma mark - Device Filters tests

/// Tests that an attempt to remove a nil device filter is handled gracefully.
- (void)testRemovingNilDeviceFilterShouldNotCrash {
    [self.provider removeDeviceFilter:nil];

    XCTAssert(YES, @"Removing nil device filter must not crash");
}

/// Tests that an attempt to remove a device filter that wasn't added before is
/// handled gracefully.
- (void)testRemovingUnknownDeviceFilterShouldNotCrash {
    NSDictionary *filter = @{kKeySSDP: @{kKeyFilter: @"some:thing"}};
    [self.provider removeDeviceFilter:filter];

    XCTAssert(YES, @"Removing not previously add device filter must not crash");
}

#pragma mark - Discovery & Delegate tests

/// Tests that -startDiscovery sets up the isRunning flag.
- (void)testShouldBeRunningAfterDiscoveryStart {
    [self.provider startDiscovery];

    XCTAssertTrue(self.provider.isRunning, @"The provider should be running after discovery start");
}

/// Tests that starting a discovery should send the correct multicast SSDP
/// M-SEARCH request, with the headers according to the UPnP specification.
- (void)testStartDiscoveryShouldSendCorrectSearchRequest {
    // Arrange
    id searchSocketMock = OCMClassMock([SSDPSocketListener class]);
    self.provider.searchSocket = searchSocketMock;

    NSDictionary *filter = @{kKeySSDP: @{kKeyFilter: @"some:thing"}};
    [self.provider addDeviceFilter:filter];

    // Act
    [self.provider startDiscovery];

    // Assert
    BOOL (^httpDataVerificationBlock)(id obj) = ^BOOL(NSData *data) {
        CFHTTPMessageRef msg = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
        XCTAssertTrue(CFHTTPMessageAppendBytes(msg, data.bytes, data.length),
                      @"Couldn't parse the HTTP request");

        // assert the SSDP search request is according to the UPnP specification
        NSString *statusLine = [@[CFBridgingRelease(CFHTTPMessageCopyRequestMethod(msg)),
                                  CFBridgingRelease(CFURLCopyPath(CFHTTPMessageCopyRequestURL(msg))),
                                  CFBridgingRelease(CFHTTPMessageCopyVersion(msg))] componentsJoinedByString:@" "];
        XCTAssertEqualObjects(statusLine, @"M-SEARCH * HTTP/1.1", @"The status line is incorrect");

        NSString *host = httpHeaderValue(msg, @"HOST");
        NSString *correctHost = [NSString stringWithFormat:@"%@:%lu",
                                 kSSDPMulticastIPAddress,
                                 (unsigned long) kSSDPMulticastTCPPort];
        XCTAssertEqualObjects(host, correctHost, @"The HOST header value is incorrect");

        NSString *man = httpHeaderValue(msg, @"MAN");
        XCTAssertEqualObjects(man, @"\"ssdp:discover\"", @"The MAN header value is incorrect");

        NSInteger mx = [httpHeaderValue(msg, @"MX") integerValue];
        XCTAssertGreaterThan(mx, 1, @"The MX header value must be > 1");
        XCTAssertLessThanOrEqual(mx, 5, @"The MX header value must be <= 5");

        NSString *searchTarget = httpHeaderValue(msg, @"ST");
        XCTAssertEqualObjects(searchTarget, filter[kKeySSDP][kKeyFilter], @"The Search Target header value is incorrect");

        NSString *userAgent = httpHeaderValue(msg, @"USER-AGENT");
        if (userAgent) {
            XCTAssertNotEqual([userAgent rangeOfString:@"UPnP/1.1"].location, NSNotFound,
                              @"The User Agent header value must include UPnP version");
        }

        NSData *body = CFBridgingRelease(CFHTTPMessageCopyBody(msg));
        XCTAssertEqual(body.length, 0, @"There must be no body");

        return YES;
    };

    OCMVerify([searchSocketMock sendData:[OCMArg checkWithBlock:httpDataVerificationBlock]
                               toAddress:kSSDPMulticastIPAddress
                                 andPort:kSSDPMulticastTCPPort]);
}

/// Tests that the delegate's -discoveryProvider:didFindService: method is
/// called with the correct service description after receiving a search
/// response. The test uses the `ssdp_device_description.xml` file for mocked
/// device description response.
- (void)testDelegateDidFindServiceShouldBeCalledAfterReceivingSearchResponse {
    // Arrange
    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    id searchSocketMock = OCMClassMock([SSDPSocketListener class]);
    self.provider.searchSocket = searchSocketMock;

    NSString *serviceType = @"urn:schemas-upnp-org:device:thing:1";
    NSDictionary *filter = @{kKeySSDP: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"SomethingNew"};
    [self.provider addDeviceFilter:filter];

    NSString *kServiceAddress = @"127.0.1.2";
    NSString *kDeviceDescriptionURL = [NSString stringWithFormat:@"http://%@:7676/root", kServiceAddress];
    NSString *kUUID = @"f21e800a-1000-ab08-8e5a-76f4fcb5e772";

    OCMStub([searchSocketMock sendData:[OCMArg isNotNil]
                             toAddress:kSSDPMulticastIPAddress
                               andPort:kSSDPMulticastTCPPort]).andDo((^(NSInvocation *invocation) {
        NSString *searchResponse = [NSString stringWithFormat:
                                    @"HTTP/1.1 200 OK\r\n"
                                    @"CACHE-CONTROL: max-age=1800\r\n"
                                    @"Date: Thu, 01 Jan 1970 04:04:04 GMT\r\n"
                                    @"EXT:\r\n"
                                    @"LOCATION: %@\r\n"
                                    @"SERVER: Linux/4.2 UPnP/1.1 MagicDevice/1.0\r\n"
                                    @"ST: %@\r\n"
                                    @"USN: uuid:%@::urn:schemas-upnp-org:device:thing:1\r\n"
                                    @"Content-Length: 0\r\n"
                                    @"\r\n",
                                    kDeviceDescriptionURL, serviceType, kUUID];
        NSData *searchResponseData = [searchResponse dataUsingEncoding:NSUTF8StringEncoding];

        [self.provider socket:searchSocketMock
               didReceiveData:searchResponseData
                  fromAddress:kServiceAddress];
    }));

    XCTestExpectation *deviceDescriptionResponseExpectation = [self expectationWithDescription:@"Device description response"];

    NSString *deviceDescriptionResponseFilePath = OHPathForFileInBundle(@"ssdp_device_description.xml", nil);
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [kDeviceDescriptionURL isEqualToString:request.URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:deviceDescriptionResponseFilePath
                                                statusCode:200
                                                   headers:nil];
    }];

    OCMExpect(([delegateMock discoveryProvider:[OCMArg isEqual:self.provider]
                                didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service.address, kServiceAddress, @"The service's address is incorrect");
        XCTAssertEqualObjects(service.serviceId, filter[kKeyServiceID], @"The service ID is incorrect");
        XCTAssertEqualObjects(service.UUID, kUUID, @"The UUID is incorrect");
        XCTAssertEqualObjects(service.type, serviceType, @"The service type is incorrect");
        XCTAssertEqualObjects(service.friendlyName, @"short user-friendly title", @"The friendly name is incorrect");
        XCTAssertEqualObjects(service.manufacturer, @"manufacturer name", @"The manufacturer is incorrect");
        XCTAssertEqualObjects(service.modelName, @"model name", @"The model name is incorrect");
        XCTAssertEqualObjects(service.modelDescription, @"long user-friendly title", @"The model description is incorrect");
        XCTAssertEqualObjects(service.modelNumber, @"model number", @"The model number is incorrect");
        XCTAssertEqualObjects(service.commandURL.absoluteString, kDeviceDescriptionURL, @"The command URL is incorrect");
        XCTAssertEqualObjects(service.locationXML, [NSString stringWithContentsOfFile:deviceDescriptionResponseFilePath
                                                                             encoding:NSUTF8StringEncoding
                                                                                error:nil], @"The XML content is incorrect");
//        XCTAssertEqual(service.port, 9999, @"The port is incorrect");
//        XCTAssertEqualObjects(service.version, @"1", @"The version is incorrect");

        XCTAssertEqual(service.serviceList.count, 1, @"The service count is incorrect");
        NSDictionary *serviceInfo = @{@"serviceType": @{@"text": @"urn:schemas-upnp-org:service:serviceType:v"},
                                      @"serviceId": @{@"text": @"urn:upnp-org:serviceId:serviceID"},
                                      @"SCPDURL": @{@"text": @"http://127.0.1.2:9999/scpd"},
                                      @"controlURL": @{@"text": @"http://127.0.1.2:9999/cnc"},
                                      @"eventSubURL": @{@"text": @"http://127.0.1.2:9999/event"},
                                      @"text": @""};
        XCTAssertEqualObjects(service.serviceList[0], serviceInfo, @"The service info is incorrect");

        [deviceDescriptionResponseExpectation fulfill];
        return YES;
    }]]));

    // Act
    [self.provider startDiscovery];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"Test timeout");
                                     OCMVerifyAll(delegateMock);
                                 }];
}

/// Tests that the delegate's -discoveryProvider:didLoseService: method is
/// called with the correct service description (matching the found one) after
/// receiving a UPnP bye-bye notification. The test uses the
/// `ssdp_device_description.xml` file for mocked device description response.
- (void)testDelegateDidLoseServiceShouldBeCalledAfterReceivingByeByeNotification {
    // Arrange
    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    id searchSocketMock = OCMClassMock([SSDPSocketListener class]);
    self.provider.searchSocket = searchSocketMock;

    NSString *serviceType = @"urn:schemas-upnp-org:device:thing:1";
    NSDictionary *filter = @{kKeySSDP: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"SomethingNew"};
    [self.provider addDeviceFilter:filter];

    NSString *kServiceAddress = @"127.0.1.2";
    NSString *kDeviceDescriptionURL = [NSString stringWithFormat:@"http://%@:7676/root", kServiceAddress];
    NSString *kUUID = @"f21e800a-1000-ab08-8e5a-76f4fcb5e772";

    OCMStub([searchSocketMock sendData:[OCMArg isNotNil]
                             toAddress:kSSDPMulticastIPAddress
                               andPort:kSSDPMulticastTCPPort]).andDo((^(NSInvocation *invocation) {
        NSString *searchResponse = [NSString stringWithFormat:
                                    @"HTTP/1.1 200 OK\r\n"
                                    @"CACHE-CONTROL: max-age=1800\r\n"
                                    @"Date: Thu, 01 Jan 1970 04:04:04 GMT\r\n"
                                    @"EXT:\r\n"
                                    @"LOCATION: %@\r\n"
                                    @"SERVER: Linux/4.2 UPnP/1.1 MagicDevice/1.0\r\n"
                                    @"ST: %@\r\n"
                                    @"USN: uuid:%@::urn:schemas-upnp-org:device:thing:1\r\n"
                                    @"Content-Length: 0\r\n"
                                    @"\r\n",
                                    kDeviceDescriptionURL, serviceType, kUUID];
        NSData *searchResponseData = [searchResponse dataUsingEncoding:NSUTF8StringEncoding];

        [self.provider socket:searchSocketMock
               didReceiveData:searchResponseData
                  fromAddress:kServiceAddress];
    }));

    XCTestExpectation *deviceDescriptionResponseExpectation = [self expectationWithDescription:@"Device description response"];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [kDeviceDescriptionURL isEqualToString:request.URL.absoluteString];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"ssdp_device_description.xml", nil)
                                                statusCode:200
                                                   headers:nil];
    }];

    __block ServiceDescription *foundService;
    OCMStub([delegateMock discoveryProvider:self.provider
                             didFindService:[OCMArg isNotNil]]).andDo(^(NSInvocation *inv) {
        // credit: http://stackoverflow.com/questions/17907987/nsinvocation-getargumentatindex-confusion-while-testing-blocks-with-ocmock#comment26357777_17907987
        __unsafe_unretained ServiceDescription *tmp;
        [inv getArgument:&tmp atIndex:3];
        foundService = tmp;

        [deviceDescriptionResponseExpectation fulfill];
    });

    NSString *byebyeNotification = [NSString stringWithFormat:
                                    @"NOTIFY * HTTP/1.1\r\n"
                                    @"HOST: 239.255.255.250:1900\r\n"
                                    @"NT: %@\r\n"
                                    @"NTS: ssdp:byebye\r\n"
                                    @"USN: uuid:%@::urn:schemas-upnp-org:device:thing:1\r\n"
                                    @"\r\n",
                                    serviceType, kUUID];
    NSData *byebyeNotificationData = [byebyeNotification dataUsingEncoding:NSUTF8StringEncoding];

    [self.provider startDiscovery];
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"Find service timeout");
                                     OCMVerifyAll(delegateMock);
                                 }];

    XCTestExpectation *didLoseServiceExpectation = [self expectationWithDescription:@"didLoseService: expectation"];
    OCMExpect([delegateMock discoveryProvider:self.provider
                               didLoseService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service, foundService, @"The lost service is not the found one");

        [didLoseServiceExpectation fulfill];
        return YES;
    }]]);

    // Act
    [self.provider socket:searchSocketMock
           didReceiveData:byebyeNotificationData
              fromAddress:kServiceAddress];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"Lose service timeout");
                                     OCMVerifyAll(delegateMock);
                                 }];
}

@end
