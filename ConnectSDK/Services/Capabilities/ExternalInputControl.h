//
// Created by Jeremy White on 1/19/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
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

typedef void (^ ExternalInputListSuccessBlock)(NSArray *externalInputList);

- (id<ExternalInputControl>)externalInputControl;
- (CapabilityPriorityLevel)externalInputControlPriority;

- (void)launchInputPickerWithSuccess:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure;
- (void)closeInputPicker:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) getExternalInputListWithSuccess:(ExternalInputListSuccessBlock)success failure:(FailureBlock)failure;
- (void) setExternalInput:(ExternalInputInfo *)externalInputInfo success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
