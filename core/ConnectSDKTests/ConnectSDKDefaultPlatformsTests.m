//
//  ConnectSDKDefaultPlatformsTests.m
//  ConnectSDKDefaultPlatformsTests
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


#import "ConnectSDKDefaultPlatforms.h"

/// Tests for the ConnectSDK's default platforms list.
@interface ConnectSDKDefaultPlatformsTests : XCTestCase

@end

@implementation ConnectSDKDefaultPlatformsTests

/// Tests that the default platforms list is defined and not empty.
- (void)testThereShouldBeDefaultPlatforms {
    NSDictionary *platforms = kConnectSDKDefaultPlatforms;
    XCTAssertGreaterThan(platforms.count, 0, @"The default platforms list must not be empty");
}

/// Tests that the default service classes are available in runtime.
/// NB: the success of this test relies on the test target's setup.
- (void)testServiceClassesAreAvailable {
    NSDictionary *platforms = kConnectSDKDefaultPlatforms;
    [platforms enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                                       usingBlock:^(NSString *key, id obj, BOOL *stop) {
                                           XCTAssertNotNil(NSClassFromString(key),
                                                           @"Service class %@ must be available at runtime", key);
                                       }];
}

/// Tests that the default discovery provider classes are available at runtime.
/// NB: the success of this test relies on the test target's setup.
- (void)testDiscoveryProviderClassesAreAvailable {
    NSDictionary *platforms = kConnectSDKDefaultPlatforms;
    // we get the unique providers only because one can be used for different
    // services
    NSSet *uniqueDiscoveryProviders = [NSSet setWithArray:platforms.allValues];
    [uniqueDiscoveryProviders enumerateObjectsWithOptions:NSEnumerationConcurrent
                                               usingBlock:^(NSString *obj, BOOL *stop) {
                                                   XCTAssertNotNil(NSClassFromString(obj),
                                                                   @"Discovery provider class %@ must be available at runtime", obj);
                                               }];
}

@end
