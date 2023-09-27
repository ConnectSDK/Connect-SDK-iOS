//
//  MouseControl.h
//  Connect SDK
//
//  Created by Jeremy White on 1/3/14.
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

#import <Foundation/Foundation.h>
#import "Capability.h"

#define kMouseControlAny @"MouseControl.Any"

#define kMouseControlConnect @"MouseControl.Connect"
#define kMouseControlDisconnect @"MouseControl.Disconnect"
#define kMouseControlClick @"MouseControl.Click"
#define kMouseControlMove @"MouseControl.Move"
#define kMouseControlScroll @"MouseControl.Scroll"

#define kMouseControlCapabilities @[\
    kMouseControlConnect,\
    kMouseControlDisconnect,\
    kMouseControlClick,\
    kMouseControlMove,\
    kMouseControlScroll\
]

@protocol MouseControl <NSObject>

- (id<MouseControl>)mouseControl;
- (CapabilityPriorityLevel)mouseControlPriority;

- (void) connectMouseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) disconnectMouse;

- (void) clickWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) move:(CGVector)distance success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) scroll:(CGVector)distance success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
