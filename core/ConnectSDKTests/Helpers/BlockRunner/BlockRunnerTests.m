//
//  BlockRunnerTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/4/15.
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

#import "BlockRunner.h"

#import <objc/runtime.h>

@interface BlockRunnerTests : XCTestCase

@end

@implementation BlockRunnerTests

- (void)testProtocolShouldInheritFromNSObject {
    XCTAssertTrue(protocol_conformsToProtocol(@protocol(BlockRunner),
                                              @protocol(NSObject)),
                  @"BlockRunner should inherit from NSObject");
}

- (void)testProtocolShouldHaveRunBlockMethod {
    struct objc_method_description desc = protocol_getMethodDescription(@protocol(BlockRunner),
                                                                        @selector(runBlock:),
                                                                        YES,
                                                                        YES);
    XCTAssertNotEqual(desc.name, NULL, @"runBlock: should be defined");
    XCTAssertNotEqual(desc.types, NULL, @"runBlock: should be defined");
}

@end
