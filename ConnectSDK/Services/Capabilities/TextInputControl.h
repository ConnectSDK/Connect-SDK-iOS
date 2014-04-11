//
// Created by Jeremy White on 1/19/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "TextInputStatusInfo.h"
#import "ServiceSubscription.h"

#define kTextInputControlAny @"TextInputControl.Any"

#define kTextInputControlSendText @"TextInputControl.Send.Text"
#define kTextInputControlSendEnter @"TextInputControl.Send.Enter"
#define kTextInputControlSendDelete @"TextInputControl.Send.Delete"
#define kTextInputControlSubscribe @"TextInputControl.Subscribe"

#define kTextInputControlCapabilities @[\
    kTextInputControlSendText,\
    kTextInputControlSendEnter,\
    kTextInputControlSendDelete,\
    kTextInputControlSubscribe\
]

@protocol TextInputControl <NSObject>

/*!
 * Response block that is fired on any change of keyboard visibility.
 * @param textInputStatusInfo provides keyboard type & visibility information
 */
typedef void (^ TextInputStatusInfoSuccessBlock)(TextInputStatusInfo *textInputStatusInfo);

- (id<TextInputControl>) textInputControl;
- (CapabilityPriorityLevel) textInputControlPriority;

- (ServiceSubscription *) subscribeTextInputStatusWithSuccess:(TextInputStatusInfoSuccessBlock)success failure:(FailureBlock)failure;

- (void) sendText:(NSString *)input success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) sendEnterWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) sendDeleteWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@end
