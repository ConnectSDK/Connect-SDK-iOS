//
//  SSDPDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-08-13.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "SSDPDiscoveryProvider.h"

#import "ServiceDescription.h"

#import "DelegateMock.h"

#import <XCTest/XCTest.h>

@interface SSDPDiscoveryProviderTests : XCTestCase

@end

@implementation SSDPDiscoveryProviderTests

- (void)testShouldDiscoverDLNADevice {
    SSDPDiscoveryProvider *provider = [SSDPDiscoveryProvider new];
    [provider addDeviceFilter:@{@"serviceId": @"A",
                                @"ssdp": @{
                                        @"filter": @"urn:schemas-upnp-org:device:MediaRenderer:1",
                                        }}];

    DelegateMock *delegateMock = [DelegateMock new];
    provider.delegate = delegateMock;

    XCTestExpectation *exp = [self expectationWithDescription:@""];
    delegateMock.exp = exp;

    [provider startDiscovery];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];

    ServiceDescription *desc = delegateMock.capturedServiceDescription;
    XCTAssertEqual([desc.address rangeOfString:@"192.168.1."].location, 0);
}

@end
