//
//  ServiceAsychCommand.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/23/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceAsyncCommand.h"

@implementation ServiceAsyncCommand

- (instancetype) initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    self = [super initWithDelegate:delegate target:target payload:payload];
    return self;
}

+ (instancetype) asyncWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    return [[ServiceAsyncCommand alloc] initWithDelegate:delegate target:target payload:payload];;
}

- (void) send
{
    if ([self.delegate respondsToSelector:@selector(sendAsync:withPayload:toURL:)])
        [self.delegate sendAsync:self withPayload:self.payload toURL:self.target];
}

@end
