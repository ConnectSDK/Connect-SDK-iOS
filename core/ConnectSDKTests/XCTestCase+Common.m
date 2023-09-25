//
//  XCTestCase+Common.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-31.
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

#import "XCTestCase+Common.h"

#import "ConnectError.h"

@implementation XCTestCase (Common)

- (void)checkOperationShouldReturnNotSupportedErrorUsingBlock:(ActionBlock)block {
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:@"This feature is not supported."};
    NSError *unsupportedError = [NSError errorWithDomain:ConnectErrorDomain
                                                    code:ConnectStatusCodeNotSupported
                                                userInfo:errorInfo];

    ActionBlock actionBlock = ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
        SuccessBlock success = ^(id response) {
            XCTFail(@"should be no success");
            successVerifier(nil);
        };
        FailureBlock failure = ^(NSError *error) {
            XCTAssertEqualObjects(error, unsupportedError, @"Error is wrong");
            failureVerifier(nil);
        };
        block(success, failure);
    };

    __block BOOL verified = NO;
    void(^blockCallVerifier)(id) = ^(id object) {
        verified = YES;
    };
    // either block should be called
    actionBlock(blockCallVerifier, blockCallVerifier);

    XCTAssertTrue(verified, @"failure block should be called");
}

@end
