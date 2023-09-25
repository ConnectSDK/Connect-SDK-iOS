//
//  ServiceSubscription.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
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

#import "ServiceCommand.h"

/// A special value identifying the @c callId is unset.
extern const int kUnsetCallId;

@interface ServiceSubscription : ServiceCommand

@property (nonatomic, readonly) int callId;
@property (nonatomic, strong) NSMutableArray *successCalls;
@property (nonatomic, strong) NSMutableArray *failureCalls;

@property (nonatomic) BOOL isSubscribed;

- (instancetype) initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload callId:(int)callId;
+ (instancetype) subscriptionWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)url payload:(id)payload callId:(int)callId;

-(void) addSuccess:(id)success;
-(void) addFailure:(FailureBlock)failure;

-(void) subscribe;
-(void) unsubscribe;

@end
