//
//  ServiceSubscription.m
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

#import "ServiceSubscription.h"

const int kUnsetCallId = -1;

@implementation ServiceSubscription

-(instancetype)initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload callId:(int)callId
{
    self = [self initWithDelegate:delegate target:target payload:payload];

    if (self)
    {
        _callId = callId;
    }

    return self;
}

-(instancetype)initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    self = [super initWithDelegate:delegate target:payload payload:payload];

    if (self)
    {
        self.target = target;
        _isSubscribed = NO;
        _callId = -1;
    }

    return self;
}

+(instancetype)subscriptionWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)url payload:(id)payload callId:(int)callId{
    ServiceSubscription *subscription = [[ServiceSubscription alloc] initWithDelegate:delegate target:url payload:payload callId:callId];
    return subscription;
}

-(void) addSuccess:(id)success{
    if(!_successCalls) _successCalls = [[NSMutableArray alloc] init];

    if (success && ![_successCalls containsObject:success])
        [_successCalls addObject:success];

    NSArray *successes = [NSArray arrayWithArray:_successCalls];
    self.callbackComplete = ^(NSDictionary*dic){
        for(int i=0; i< [successes count]; i++){
            ((SuccessBlock)[successes objectAtIndex:i])(dic);
        }
    };
}
-(void)addFailure:(FailureBlock)failure
{
    if(!_failureCalls) _failureCalls = [[NSMutableArray alloc] init];

    if (failure && ![_failureCalls containsObject:failure])
        [_failureCalls addObject:failure];

    NSArray *fails = [NSArray arrayWithArray:_failureCalls];
    self.callbackError = ^(NSError*err){
        for(int i=0; i< [fails count]; i++){
            ((FailureBlock)[fails objectAtIndex:i])(err);
        }
    };
}

-(void) subscribe
{
    if ([self.delegate respondsToSelector:@selector(sendSubscription:type:payload:toURL:withId:)])
    {
        _callId = [self.delegate sendSubscription:self type:ServiceSubscriptionTypeSubscribe payload:self.payload toURL:self.target withId:_callId];
        _isSubscribed = true;
    }
}

//Override for semantic clarity
-(void) cancel
{
    [self unsubscribe];
}

-(void) unsubscribe
{
    if ([self.delegate respondsToSelector:@selector(sendSubscription:type:payload:toURL:withId:)])
    {
        _callId = [self.delegate sendSubscription:self type:ServiceSubscriptionTypeUnsubscribe payload:self.payload toURL:self.target withId:_callId];
        _isSubscribed = false;
    }

    _successCalls = nil;
    _failureCalls = nil;
}

-(instancetype) clone
{
    ServiceSubscription *clone = [ServiceSubscription subscriptionWithDelegate:self.delegate target:[self.target copy] payload:[self.payload copy] callId:_callId];
    return clone;
}

#pragma mark - Debugging

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: callId=%ld; target=%@; "
            @"payload=%@; #successCallbacks=%ld; #failureCallbacks=%ld>",
            NSStringFromClass([self class]), (unsigned long)self.callId,
            self.target, self.payload, (unsigned long)self.successCalls.count,
            (unsigned long)self.failureCalls.count];
}

@end
