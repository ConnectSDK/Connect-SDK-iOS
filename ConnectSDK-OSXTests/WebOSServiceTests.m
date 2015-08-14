//
//  WebOSServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-08-14.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DiscoveryManager.h"
#import "SSDPDiscoveryProvider.h"
#import "WebOSTVService.h"

#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <Specta/Specta.h>

SpecBegin(WebOSService)

it(@"should connect to WebOS", ^{
    DiscoveryManager *manager = [DiscoveryManager new];
    manager.deviceStore = nil;

    id delegateStub = OCMProtocolMock(@protocol(DiscoveryManagerDelegate));
    manager.delegate = delegateStub;

    [manager registerDeviceService:[WebOSTVService class]
                     withDiscovery:[SSDPDiscoveryProvider class]];

    __block WebOSTVService *service;
    waitUntil(^(DoneCallback done) {
        OCMStub([delegateStub discoveryManager:manager
                                 didFindDevice:
                 [OCMArg checkWithBlock:^BOOL(ConnectableDevice *device) {
            service = (WebOSTVService *)[device serviceWithName:kConnectSDKWebOSTVServiceId];

            done();
            return YES;
        }]]);

        [manager startDiscovery];
    });

    delegateStub = nil;

    expect(service).notTo.beNil();
    expect(service).beAKindOf([WebOSTVService class]);
});

SpecEnd
