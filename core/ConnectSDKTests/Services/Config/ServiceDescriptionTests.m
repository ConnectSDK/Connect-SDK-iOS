//
//  ServiceDescriptionTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/5/15.
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

#import "ServiceDescription.h"

@interface ServiceDescriptionTests : XCTestCase

@end

@implementation ServiceDescriptionTests

#pragma mark - Equality Tests

- (void)testInstancesWithNilDevicesShouldBeEqual {
    ServiceDescription *sd1 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd1.device = nil;
    ServiceDescription *sd2 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd2.device = nil;
    XCTAssertEqualObjects(sd1, sd2,
                          @"Two instances with equal address and UUID should be equal without devices");
    XCTAssertEqual(sd1.hash, sd2.hash, @"And hashes should be equal");
}

- (void)testInstancesWithSameDevicesShouldBeEqual {
    id abstractDevice = @"device";
    ServiceDescription *sd1 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd1.device = abstractDevice;
    ServiceDescription *sd2 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd2.device = abstractDevice;
    XCTAssertEqualObjects(sd1, sd2,
                          @"Two instances with equal address and UUID should be equal with the same devices");
    XCTAssertEqual(sd1.hash, sd2.hash, @"And hashes should be equal");
}

- (void)testInstancesWithEqualDevicesShouldBeEqual {
    ServiceDescription *sd1 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd1.device = @{@"key": @"device"};
    ServiceDescription *sd2 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd2.device = @{@"key": @"device"};

    // safety check
    XCTAssertEqualObjects(sd1.device, sd2.device, @"Devices should be equal objects");
    XCTAssertNotEqual(sd1.device, sd2.device, @"but should not be equal pointers");

    XCTAssertEqualObjects(sd1, sd2,
                          @"Two instances with equal address and UUID should be equal with the equal devices");
    XCTAssertEqual(sd1.hash, sd2.hash, @"And hashes should be equal");
}

- (void)testInstancesWithNotEqualDevicesShouldNotBeEqual {
    ServiceDescription *sd1 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd1.device = @"device1";
    ServiceDescription *sd2 = [ServiceDescription descriptionWithAddress:@"1"
                                                                    UUID:@"2"];
    sd2.device = @"device2";

    // safety check
    XCTAssertNotEqualObjects(sd1.device, sd2.device, @"Devices should not be equal objects");
    XCTAssertNotEqual(sd1.hash, sd2.hash, @"Devices should not have equal hashes");

    XCTAssertNotEqualObjects(sd1, sd2,
                             @"Two instances with equal address and UUID should not be equal with not equal devices");
    XCTAssertNotEqual(sd1.hash, sd2.hash, @"And hashes should not be equal");
}

@end
