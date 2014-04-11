//
// Created by Jeremy White on 1/19/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"

#define kPowerControlAny @"PowerControl.Any"

#define kPowerControlOff @"PowerControl.Off"

#define kPowerControlCapabilities @[\
    kPowerControlOff\
]

@protocol PowerControl <NSObject>

- (id<PowerControl>)powerControl;
- (CapabilityPriorityLevel)powerControlPriority;

- (void) powerOffWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@end
