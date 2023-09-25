//
//  TextInputControl.h
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
 *
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
