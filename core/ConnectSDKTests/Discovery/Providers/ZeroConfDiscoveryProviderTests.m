//
//  ZeroConfDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/18/14.
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


#import <arpa/inet.h>


#import "ZeroConfDiscoveryProvider_Private.h"
#import "ServiceDescription.h"

static NSString *const kKeyZeroconf = @"zeroconf";
static NSString *const kKeyFilter = @"filter";
static NSString *const kKeyServiceID = @"serviceId";


/// Tests for the ZeroConfDiscoveryProvider class.
/// NSNetServiceBrowser and NSNetService classes are mocked to avoid using the
/// real networking and verify the interactions are correct.
@interface ZeroConfDiscoveryProviderTests : XCTestCase

@property (nonatomic, strong) ZeroConfDiscoveryProvider *provider;

@end

@implementation ZeroConfDiscoveryProviderTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.provider = [ZeroConfDiscoveryProvider new];
}

- (void)tearDown {
    self.provider = nil;

    [super tearDown];
}

#pragma mark - Discovery & Delegate tests

/// Tests that -startDiscovery starts to search for services of the specified
/// type.
- (void)testStartDiscoveryShouldSearchForServices {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType}};
    [self.provider addDeviceFilter:filter];

    // Act
    [self.provider startDiscovery];

    // Assert
    OCMVerify([serviceBrowserMock searchForServicesOfType:serviceType
                                                 inDomain:@"local."]);
}

/// Tests that -stopDiscovery stops searching for services.
- (void)testStopDiscoveryShouldStopServiceBrowser {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    // Act
    [self.provider startDiscovery];
    [self.provider stopDiscovery];

    // Assert
    OCMVerify([serviceBrowserMock stop]);
}

/// Tests that a found service is asked to resolve the addresses.
- (void)testShouldResolveServiceAfterDiscovering {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType}};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    // Act
    [self.provider startDiscovery];

    // Assert
    [[[netServiceMock verify] ignoringNonObjectArgs] resolveWithTimeout:0];
}

/// Tests that the delegate's -discoveryProvider:didFindService: method is
/// called with the correct service description after resolving a service
/// successfully.
- (void)testShouldCallDelegateDidFindServiceAfterResolvingService {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"ZeroService"};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");
    OCMStub([(NSNetService *)netServiceMock type]).andReturn(serviceType);

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    NSString *kServiceAddress = @"10.8.8.8";
    static const NSUInteger kServicePort = 8889;

    struct sockaddr_in socket;
    bzero(&socket, sizeof(socket));
    socket.sin_family = AF_INET;
    socket.sin_port = htons(kServicePort);
    XCTAssertEqual(inet_pton(socket.sin_family, [kServiceAddress UTF8String], &socket.sin_addr), 1, @"Failed to prepare mocked IP address");
    NSData *socketData = [NSData dataWithBytes:&socket length:sizeof(socket)];
    NSArray *addresses = @[socketData];
    OCMStub([netServiceMock addresses]).andReturn(addresses);

    [[[[netServiceMock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.provider netServiceDidResolveAddress:netServiceMock];
        });
    }] resolveWithTimeout:0];

    XCTestExpectation *didFindServiceExpectation = [self expectationWithDescription:@"didFindService: is called"];
    OCMExpect([delegateMock discoveryProvider:self.provider
                               didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service.address, kServiceAddress, @"The service's address is incorrect");
        XCTAssertEqual(service.port, kServicePort, @"The port is incorrect");
        XCTAssertEqualObjects(service.serviceId, filter[kKeyServiceID], @"The service ID is incorrect");
        XCTAssertEqualObjects(service.UUID, [netServiceMock name], @"The UUID is incorrect");
        XCTAssertEqualObjects(service.friendlyName, [netServiceMock name], @"The friendly name is incorrect");
        XCTAssertNil(service.manufacturer, @"The manufacturer should be nil");
        XCTAssertNil(service.modelName, @"The model name should be nil");
        XCTAssertNil(service.modelDescription, @"The model description should be nil");
        XCTAssertNil(service.modelNumber, @"The model number should be nil");
        XCTAssertEqualObjects(service.commandURL.absoluteString, ([NSString stringWithFormat:@"http://%@:%lu/", kServiceAddress, (unsigned long)kServicePort]), @"The command URL is incorrect");
        XCTAssertNil(service.locationXML, @"The XML content should be nil");
//        XCTAssertEqualObjects(service.type, [(NSNetService *)netServiceMock type], @"The service type is incorrect");
//        XCTAssertEqualObjects(service.version, @"1", @"The version is incorrect");
        XCTAssertNil(service.serviceList, @"The service list should be nil");

        [didFindServiceExpectation fulfill];
        return YES;
    }]]);

    // Act
    [self.provider startDiscovery];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"didFindService: isn't called");
                                     OCMVerifyAll(delegateMock);
                                 }];
}

/// Tests that the delegate's -discoveryProvider:didLoseService: method is
/// called with the correct service description (mathcing the found one) after
/// removing a previously found service.
- (void)testShouldCallDelegateDidLoseServiceAfterRemovingService {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"ZeroService"};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");
    OCMStub([(NSNetService *)netServiceMock type]).andReturn(serviceType);

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    NSString *kServiceAddress = @"10.8.8.8";
    static const NSUInteger kServicePort = 8889;

    struct sockaddr_in socket;
    bzero(&socket, sizeof(socket));
    socket.sin_family = AF_INET;
    socket.sin_port = htons(kServicePort);
    XCTAssertEqual(inet_pton(socket.sin_family, [kServiceAddress UTF8String], &socket.sin_addr), 1, @"Failed to prepare mocked IP address");
    NSData *socketData = [NSData dataWithBytes:&socket length:sizeof(socket)];
    NSArray *addresses = @[socketData];
    OCMStub([netServiceMock addresses]).andReturn(addresses);

    [[[[netServiceMock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.provider netServiceDidResolveAddress:netServiceMock];
        });
    }] resolveWithTimeout:0];

    XCTestExpectation *didFindServiceExpectation = [self expectationWithDescription:@"didFindService: is called"];

    __block ServiceDescription *foundService;
    OCMStub([delegateMock discoveryProvider:self.provider
                             didFindService:[OCMArg isNotNil]]).andDo(^(NSInvocation *inv) {
        __unsafe_unretained ServiceDescription *tmp;
        [inv getArgument:&tmp atIndex:3];
        foundService = tmp;

        [didFindServiceExpectation fulfill];
    });

    [self.provider startDiscovery];
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"didFindService: isn't called");
                                     OCMVerifyAll(delegateMock);
                                 }];

    XCTestExpectation *didLoseServiceExpectation = [self expectationWithDescription:@"didLoseService: is called"];
    OCMExpect([delegateMock discoveryProvider:self.provider
                               didLoseService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service, foundService, @"The lost service is not the found one");

        [didLoseServiceExpectation fulfill];
        return YES;
    }]]);

    // Act
    [self.provider netServiceBrowser:serviceBrowserMock
                    didRemoveService:netServiceMock
                          moreComing:NO];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"Lose service timeout");
                                     OCMVerifyAll(delegateMock);
                                 }];
}

/// Tests that the delegate's -discoveryProvider:didFindService: method is not
/// called if a service is resolved with no addresses.
- (void)testShouldNotCallDelegateDidFindServiceAfterFindingServiceWithNoAddresses {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"ZeroService"};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");
    OCMStub([(NSNetService *)netServiceMock type]).andReturn(serviceType);

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    NSArray *addresses = @[];
    OCMStub([netServiceMock addresses]).andReturn(addresses);

    [[[[netServiceMock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.provider netServiceDidResolveAddress:netServiceMock];
        });
    }] resolveWithTimeout:0];

    OCMStub([delegateMock discoveryProvider:self.provider
                             didFindService:[OCMArg isNotNil]]).andDo(^(NSInvocation *inv) {
        XCTFail(@"didFindService: should not be called");
    });

    // Act
    [self.provider startDiscovery];

    // Assert
    // XCTestExpectation doesn't work in this case, because it fails the test on
    // timeout, whereas we need to catch that event
    NSDate *const timeoutDate = [NSDate dateWithTimeIntervalSinceNow:kDefaultAsyncTestTimeout];
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutDate];
    }
}

/// Tests that the delegate's -discoveryProvider:didLoseService: method is not
/// called when removing a found service with no resolved addresses.
- (void)testShouldNotCallDelegateDidLoseServiceAfterRemovingServiceWithNoAddresses {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"ZeroService"};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");
    OCMStub([(NSNetService *)netServiceMock type]).andReturn(serviceType);

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    NSArray *addresses = @[];
    OCMStub([netServiceMock addresses]).andReturn(addresses);

    [[[[netServiceMock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.provider netServiceDidResolveAddress:netServiceMock];
        });
    }] resolveWithTimeout:0];

    OCMStub([delegateMock discoveryProvider:self.provider
                             didFindService:OCMOCK_ANY]).andDo(^(NSInvocation *_) {
        XCTFail(@"didFindService: should not be called");
    });

    [self.provider startDiscovery];

    // XCTestExpectation doesn't work in this case, because it fails the test on
    // timeout, whereas we need to catch that event
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:kDefaultAsyncTestTimeout];
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutDate];
    }

    OCMStub([delegateMock discoveryProvider:self.provider
                             didLoseService:OCMOCK_ANY]).andDo(^(NSInvocation *_) {
        XCTFail(@"didLoseService: should not be called");
    });

    // Act
    [self.provider netServiceBrowser:serviceBrowserMock
                    didRemoveService:netServiceMock
                          moreComing:NO];

    // Assert
    timeoutDate = [NSDate dateWithTimeIntervalSinceNow:kDefaultAsyncTestTimeout];
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:timeoutDate];
    }
}

#pragma mark - IPv6 (lack of) support tests

/// Tests that resolved services with IPv6 addresses only should be ignored.
- (void)testShouldIgnoreResolvedIPv6Address {
    // Arrange
    uint8_t ip6Bytes[] = {0x1c, 0x1e, 0x1b, 0x58, 0x00, 0x00, 0x00, 0x00, 0xfe,
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x48, 0xe3, 0xce, 0xd1,
        0x70, 0x68, 0x61, 0x04, 0x00, 0x00, 0x00};
    NSData *ip6Data = [NSData dataWithBytes:ip6Bytes length:sizeof(ip6Bytes)];

    NSArray *addresses = @[ip6Data];

    id netServiceMock = OCMClassMock([NSNetService class]);
    [OCMStub([netServiceMock name]) andReturn:@"zeroservice"];
    [OCMStub([netServiceMock addresses]) andReturn:addresses];

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    [OCMStub([delegateMock discoveryProvider:self.provider
                              didFindService:OCMOCK_ANY]) andDo:^(NSInvocation *_) {
        XCTFail(@"Should not be called for IPv6 address only");
    }];
    self.provider.delegate = delegateMock;

    // Act
    [self.provider netServiceDidResolveAddress:netServiceMock];

    // Assert
    OCMVerifyAll(delegateMock);
}

/// Tests that the IPv4 address is picked between resolved IPv6 and IPv4
/// addresses, and provided in the @c ServiceDescription.
- (void)testShouldCallDelegateWithIPv4AndNotIPv6Address {
    // Arrange
    uint8_t ip4Bytes[] = {0x10, 0x02, 0x1b, 0x58, 0xc0, 0xa8, 0x01, 0x84, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    NSData *ip4Data = [NSData dataWithBytes:ip4Bytes length:sizeof(ip4Bytes)];

    uint8_t ip6Bytes[] = {0x1c, 0x1e, 0x1b, 0x58, 0x00, 0x00, 0x00, 0x00, 0xfe,
        0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0c, 0x48, 0xe3, 0xce, 0xd1,
        0x70, 0x68, 0x61, 0x04, 0x00, 0x00, 0x00};
    NSData *ip6Data = [NSData dataWithBytes:ip6Bytes length:sizeof(ip6Bytes)];

    NSArray *addresses = @[ip4Data, ip6Data];

    id netServiceMock = OCMClassMock([NSNetService class]);
    [OCMStub([netServiceMock name]) andReturn:@"zeroservice"];
    [OCMStub([netServiceMock addresses]) andReturn:addresses];

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    OCMExpect([delegateMock discoveryProvider:self.provider
                               didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *description) {
        XCTAssertEqualObjects(description.commandURL.absoluteString,
                              @"http://192.168.1.132:7000/",
                              @"CommandURL should use IPv4 address");
        return YES;
    }]]);
    self.provider.delegate = delegateMock;

    // Act
    [self.provider netServiceDidResolveAddress:netServiceMock];

    // Assert
    OCMVerifyAll(delegateMock);
}

@end
