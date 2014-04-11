//
//  ServiceCommand.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceCommandDelegate.h"
#import "Capability.h"

@interface ServiceCommand : NSObject

@property (nonatomic, weak) id<ServiceCommandDelegate> delegate;
@property (nonatomic, copy) SuccessBlock callbackComplete;
@property (nonatomic, copy) FailureBlock callbackError;
@property (nonatomic, strong) NSString *HTTPMethod;
@property (nonatomic, strong) id payload;
@property (nonatomic, strong) NSURL *target;


- (instancetype) initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)url payload:(id)payload;
+ (instancetype) commandWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)url payload:(id)payload;

-(void) send;

@end
