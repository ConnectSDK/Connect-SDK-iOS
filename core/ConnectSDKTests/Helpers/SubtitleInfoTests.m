//
//  SubtitleInfoTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-14.
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

#import "SubtitleInfo.h"

@interface SubtitleInfoTests : XCTestCase

@property (nonatomic, strong) NSURL *url;

@end

@implementation SubtitleInfoTests

- (void)setUp {
    [super setUp];

    self.url = [NSURL URLWithString:@"http://example.com/"];
}

#pragma mark - Init Tests

- (void)testDefaultInitShouldThrowException {
    XCTAssertThrowsSpecificNamed([SubtitleInfo new],
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Default initializer is not permitted");
}

- (void)testInfoConstructorShouldNotAcceptNilURL {
    NSURL *nilUrl = [NSURL URLWithString:nil];
    XCTAssertThrowsSpecificNamed([SubtitleInfo infoWithURL:nilUrl],
                                 NSException,
                                 NSInternalInconsistencyException);
}

- (void)testInfoConstructorWithBuilderShouldNotAcceptNilURL {
    NSURL *nilUrl = [NSURL URLWithString:nil];
    XCTAssertThrowsSpecificNamed([SubtitleInfo infoWithURL:nilUrl
                                                  andBlock:^(SubtitleInfoBuilder *_) {
                                                  }],
                                 NSException,
                                 NSInternalInconsistencyException);
}

- (void)testInfoConstructorShouldSetURL {
    SubtitleInfo *info = [SubtitleInfo infoWithURL:self.url];
    XCTAssertEqualObjects(info.url, self.url);
}

- (void)testInfoConstructorShouldLeaveOptionalPropertiesNil {
    SubtitleInfo *info = [SubtitleInfo infoWithURL:self.url];
    XCTAssertNil(info.mimeType);
    XCTAssertNil(info.language);
    XCTAssertNil(info.label);
}

- (void)testBuilderShouldSetProperties {
    SubtitleInfo *info = [SubtitleInfo infoWithURL:self.url
                                          andBlock:^(SubtitleInfoBuilder *builder) {
                                              builder.mimeType = @"text/vtt";
                                              builder.language = @"en";
                                              builder.label = @"Test";
                                          }];

    XCTAssertEqualObjects(info.url, self.url);
    XCTAssertEqualObjects(info.mimeType, @"text/vtt");
    XCTAssertEqualObjects(info.language, @"en");
    XCTAssertEqualObjects(info.label, @"Test");
}

@end
