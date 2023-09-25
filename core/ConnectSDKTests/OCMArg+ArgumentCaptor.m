//
//  OCMArg+ArgumentCaptor.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/13/15.
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

#import "OCMArg+ArgumentCaptor.h"

@implementation OCMArg (ArgumentCaptor)

+ (id __nonnull)captureTo:(out id __nullable __strong *__nonnull)objectPointer {
    return [self checkWithBlock:^BOOL(id obj) {
        *objectPointer = obj;
        return YES;
    }];
}

+ (id __nonnull)captureBlockTo:(out VoidBlock __nullable __strong * __nonnull)blockPointer {
    return [self checkWithBlock:^BOOL(id obj) {
        *blockPointer = [obj copy];
        return YES;
    }];
}

@end
