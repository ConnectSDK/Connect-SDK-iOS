//
//  ExternalInputControl.h
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
#import "ExternalInputInfo.h"
#import "AppInfo.h"

#define kExternalInputControlAny @"ExternalInputControl.Any"

#define kExternalInputControlPickerLaunch @"ExternalInputControl.Picker.Launch"
#define kExternalInputControlPickerClose @"ExternalInputControl.Picker.Close"
#define kExternalInputControlList @"ExternalInputControl.List"
#define kExternalInputControlSet @"ExternalInputControl.Set"

#define kExternalInputControlCapabilities @[\
    kExternalInputControlPickerLaunch,\
    kExternalInputControlPickerClose,\
    kExternalInputControlList,\
    kExternalInputControlSet\
]

@protocol ExternalInputControl <NSObject>

/*!
 * Success block that is called upon successfully getting the external input list.
 *
 * @param externalInputList Array containing an ExternalInputInfo object for each available external input on the device
 */
typedef void (^ ExternalInputListSuccessBlock)(NSArray *externalInputList);

- (id<ExternalInputControl>)externalInputControl;
- (CapabilityPriorityLevel)externalInputControlPriority;

- (void)launchInputPickerWithSuccess:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)closeInputPicker:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) getExternalInputListWithSuccess:(ExternalInputListSuccessBlock)success failure:(FailureBlock)failure;
- (void) setExternalInput:(ExternalInputInfo *)externalInputInfo success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
