//
//  CapabilityFilter.m
//  Connect SDK
//
//  Created by Jeremy White on 1/29/14.
//  Copyright (c) 2014 LG Electronics.
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

#import "CapabilityFilter.h"


@implementation CapabilityFilter

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _capabilities = [[NSArray alloc] init];
    }

    return self;
}

+ (CapabilityFilter *)filterWithCapabilities:(NSArray *)capabilities
{
    CapabilityFilter *filter = [[CapabilityFilter alloc] init];
    [filter addCapabilities:capabilities];

    return filter;
}

- (void)addCapability:(NSString *)capability
{
    _capabilities = [_capabilities arrayByAddingObject:capability];
}

- (void)addCapabilities:(NSArray *)capabilities
{
    _capabilities = [_capabilities arrayByAddingObjectsFromArray:capabilities];
}

@end
