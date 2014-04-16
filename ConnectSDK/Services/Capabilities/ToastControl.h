//
//  ToastControl.h
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
#import "AppInfo.h"

#define kToastControlAny @"ToastControl.Any"

#define kToastControlShowToast @"ToastControl.Show"
#define kToastControlShowClickableToastApp @"ToastControl.Show.Clickable.App"
#define kToastControlShowClickableToastAppParams @"ToastControl.Show.Clickable.App.Params"
#define kToastControlShowClickableToastURL @"ToastControl.Show.Clickable.URL"

#define kToastControlCapabilities @[\
    kToastControlShowToast,\
    kToastControlShowClickableToastApp,\
    kToastControlShowClickableToastAppParams,\
    kToastControlShowClickableToastURL\
]

@protocol ToastControl <NSObject>

- (id<ToastControl>)toastControl;
- (CapabilityPriorityLevel)toastControlPriority;

- (void) showToast:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) showToast:(NSString *)message iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) showClickableToast:(NSString *)message appInfo:(AppInfo *)appInfo params:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) showClickableToast:(NSString *)message appInfo:(AppInfo *)appInfo params:(NSDictionary *)params iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure;

- (void) showClickableToast:(NSString *)message URL:(NSURL *)URL success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) showClickableToast:(NSString *)message URL:(NSURL *)URL iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
