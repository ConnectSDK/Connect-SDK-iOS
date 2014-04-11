//
// Created by Jeremy White on 1/3/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
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
- (void) moveWithX:(double)xVal andY:(double)yVal success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) scrollWithX:(double)xVal andY:(double)yVal success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
