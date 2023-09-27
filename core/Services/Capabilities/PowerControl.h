//
//  PowerControl.h
//  Connect SDK
//
//  Created by Jeremy White on 1/19/14.
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

#define kPowerControlAny @"PowerControl.Any"

#define kPowerControlOff @"PowerControl.Off"
#define kPowerControlOn @"PowerControl.On"

#define kPowerControlCapabilities @[\
    kPowerControlOff,\
    kPowerControlOn\
]

@protocol PowerControl <NSObject>

- (id<PowerControl>)powerControl;
- (CapabilityPriorityLevel)powerControlPriority;

- (void) powerOffWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) powerOnWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@end
