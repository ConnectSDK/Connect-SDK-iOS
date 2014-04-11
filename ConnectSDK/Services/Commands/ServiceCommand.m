//
//  ServiceCommand.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceCommand.h"

@implementation ServiceCommand{
    int _dataId;
}

-(instancetype)initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    self = [super init];

    if (self)
    {
        _delegate = delegate;
        _target = target;
        _payload = payload;
        _dataId = -1;
        _HTTPMethod = @"POST";
    }

    return self;
}

+ (instancetype) commandWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    return [[ServiceCommand alloc] initWithDelegate:delegate target:target payload:payload];
}

- (void) send
{
    if ([_delegate respondsToSelector:@selector(sendCommand:withPayload:toURL:)])
        /*_dataId = */[_delegate sendCommand:self withPayload:self.payload toURL:self.target];
}

- (instancetype) clone
{
    ServiceCommand *clone = [ServiceCommand commandWithDelegate:self.delegate target:self.target payload:self.payload];
    clone.callbackComplete = self.callbackComplete;
    clone.callbackError = self.callbackError;
    return clone;
}

@end
