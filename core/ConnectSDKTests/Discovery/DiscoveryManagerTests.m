//
//  DiscoveryManagerTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-06-19.
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

#import "DiscoveryManager_Private.h"

#import "AppStateChangeNotifier.h"
#import "DiscoveryProvider.h"

#import "OCMArg+ArgumentCaptor.h"

@interface MockDeviceService : DeviceService @end
@implementation MockDeviceService

+ (NSDictionary *)discoveryParameters {
    return @{@"serviceId": @"mockService"};
}

@end



@interface DiscoveryManagerTests : XCTestCase

@property (nonatomic, strong) DiscoveryManager *discoveryManager;
@property (nonatomic, strong) id /*AppStateChangeNotifier **/ stateNotifierMock;
@property (nonatomic, strong) id /*DiscoveryProvider **/ discoveryProviderMock;

@end

@implementation DiscoveryManagerTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.stateNotifierMock = OCMClassMock([AppStateChangeNotifier class]);
    self.discoveryProviderMock = OCMClassMock([DiscoveryProvider class]);
    self.discoveryManager = [self createDiscoveryManager];
}

- (DiscoveryManager *)createDiscoveryManager {
    DiscoveryManager *discoveryManager = [[DiscoveryManager alloc]
                                          initWithAppStateChangeNotifier:self.stateNotifierMock];
    [discoveryManager registerDeviceService:[MockDeviceService class]
               withDiscoveryProviderFactory:^{
                   return self.discoveryProviderMock;
               }];

    return discoveryManager;
}

- (void)tearDown {
    [self.discoveryManager stopDiscovery];
    self.discoveryManager = nil;
    self.stateNotifierMock = nil;

    [super tearDown];
}

#pragma mark - UIApplication State Change Tests

- (void)testDefaultStateNotifierShouldBeCreated {
    DiscoveryManager *discoveryManager = [DiscoveryManager new];
    XCTAssertNotNil(discoveryManager.appStateChangeNotifier,
                    @"a real AppStateChangeNotifier should be created");
}

- (void)testStartDiscoveryShouldStartListeningStateNotifier {
    OCMExpect([self.stateNotifierMock startListening]);
    [self.discoveryManager startDiscovery];
    OCMVerifyAll(self.stateNotifierMock);
}

- (void)testStopDiscoveryShouldStopListeningStateNotifier {
    OCMExpect([self.stateNotifierMock stopListening]);
    [self.discoveryManager startDiscovery];
    [self.discoveryManager stopDiscovery];
    OCMVerifyAll(self.stateNotifierMock);
}

- (void)testBackgroundingShouldPauseDiscoveryProviders {
    AppStateChangeBlock backgroundStateBlock;
    OCMExpect([self.stateNotifierMock setDidBackgroundBlock:
               [OCMArg captureBlockTo:&backgroundStateBlock]]);

    DiscoveryManager *discoveryManager = [self createDiscoveryManager];
    [discoveryManager startDiscovery];

    OCMExpect([self.discoveryProviderMock pauseDiscovery]);
    backgroundStateBlock();
    OCMVerifyAll(self.discoveryProviderMock);
}

- (void)testForegroundingShouldResumeDiscoveryProviders {
    AppStateChangeBlock backgroundStateBlock;
    AppStateChangeBlock foregroundStateBlock;
    OCMExpect([self.stateNotifierMock setDidBackgroundBlock:
               [OCMArg captureBlockTo:&backgroundStateBlock]]);
    OCMExpect([self.stateNotifierMock setDidForegroundBlock:
               [OCMArg captureBlockTo:&foregroundStateBlock]]);

    DiscoveryManager *discoveryManager = [self createDiscoveryManager];
    [discoveryManager startDiscovery];

    backgroundStateBlock();
    OCMExpect([self.discoveryProviderMock resumeDiscovery]);
    foregroundStateBlock();
    OCMVerifyAll(self.discoveryProviderMock);
}

@end
