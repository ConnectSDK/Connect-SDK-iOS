//
//  SubtitleInfo.m
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

#import "CommonMacros.h"

NS_ASSUME_NONNULL_BEGIN
@implementation SubtitleInfo

#pragma mark - Init

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Please use parameterized initializers to create an instance"
                                 userInfo:nil];
}

+ (instancetype)infoWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url];
}

+ (instancetype)infoWithURL:(NSURL *)url
                   andBlock:(void (^)(SubtitleInfoBuilder *builder))block {
    SubtitleInfoBuilder *builder = [SubtitleInfoBuilder new];
    block(builder);
    return [[self alloc] initWithURL:url andBuilder:builder];
}

#pragma mark - Private Init

- (instancetype)initWithURL:(NSURL *)url {
    return [self initWithURL:url andBuilder:nil];
}

- (instancetype)initWithURL:(NSURL *)url
                 andBuilder:(nullable SubtitleInfoBuilder *)builder /*NS_DESIGNATED_INITIALIZER*/ {
    _assert_state(nil != url, @"nil URL is not permitted");

    self = [super init];

    _url = url;
    _mimeType = builder.mimeType;
    _language = builder.language;
    _label = builder.label;

    return self;
}

@end


@implementation SubtitleInfoBuilder

@end
NS_ASSUME_NONNULL_END
