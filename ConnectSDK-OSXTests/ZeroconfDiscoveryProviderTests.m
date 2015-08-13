//
//  ZeroconfDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-08-13.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "ZeroConfDiscoveryProvider.h"

#import "ServiceDescription.h"

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

@interface DelegateMock : NSObject <DiscoveryProviderDelegate>
@property (nonatomic, strong) XCTestExpectation *exp;
@property (nonatomic, strong) ServiceDescription *capturedServiceDescription;
@end

@implementation DelegateMock

- (void)discoveryProvider:(DiscoveryProvider *)provider
           didFindService:(ServiceDescription *)description {
    self.capturedServiceDescription = description;
    [self.exp fulfill];
}

@end


@interface ZeroConfDiscoveryProviderTests : XCTestCase

@end

@implementation ZeroConfDiscoveryProviderTests

- (void)testShouldDiscoverAppleTVDevice {
    ZeroConfDiscoveryProvider *provider = [ZeroConfDiscoveryProvider new];
    [provider addDeviceFilter:@{@"serviceId": @"A",
                                @"zeroconf": @{
                                        @"filter": @"_airplay._tcp"
                                        }}];

    DelegateMock *delegateMock = [DelegateMock new];
    provider.delegate = delegateMock;

    XCTestExpectation *exp = [self expectationWithDescription:@""];
    delegateMock.exp = exp;

    [provider startDiscovery];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    ServiceDescription *desc = delegateMock.capturedServiceDescription;
    XCTAssertNotEqual([desc.friendlyName rangeOfString:@"Apple TV"].location,
                      NSNotFound);
    XCTAssertEqual([desc.address rangeOfString:@"192.168.1."].location, 0);
}

@end
