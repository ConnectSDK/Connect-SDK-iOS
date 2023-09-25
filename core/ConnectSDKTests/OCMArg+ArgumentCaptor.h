//
//  OCMArg+ArgumentCaptor.h
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

#import <OCMock/OCMArg.h>

NS_ASSUME_NONNULL_BEGIN
@interface OCMArg (ArgumentCaptor)

/// A block type that has no arguments and no return value.
typedef dispatch_block_t VoidBlock;

/// Convenience method to capture an argument for later use/verification.
+ (id)captureTo:(out __strong __nullable id *__nonnull)objectPointer;

/// Convenience method to capture a block argument for later use/verification.
+ (id)captureBlockTo:(out __strong __nullable VoidBlock *__nonnull)blockPointer;

@end
NS_ASSUME_NONNULL_END
