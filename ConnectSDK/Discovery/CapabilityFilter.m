//
// Created by Jeremy White on 1/29/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "CapabilityFilter.h"


@implementation CapabilityFilter

- (id)init
{
    self = [super init];

    if (self)
    {
        _capabilities = [[NSArray alloc] init];
    }

    return self;
}

+ (CapabilityFilter *)filterWithCapabilities:(NSArray *)capabilities
{
    CapabilityFilter *filter = [[CapabilityFilter alloc] init];
    [filter addCapabilities:capabilities];

    return filter;
}

- (void)addCapability:(NSString *)capability
{
    _capabilities = [_capabilities arrayByAddingObject:capability];
}

- (void)addCapabilities:(NSArray *)capabilities
{
    _capabilities = [_capabilities arrayByAddingObjectsFromArray:capabilities];
}

@end
