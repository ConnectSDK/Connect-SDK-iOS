//
//  ServiceSubscription.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceCommand.h"

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
