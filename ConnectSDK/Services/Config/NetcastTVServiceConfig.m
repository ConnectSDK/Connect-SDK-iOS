//
// Created by Jeremy White on 12/30/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "NetcastTVServiceConfig.h"


@implementation NetcastTVServiceConfig

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self)
    {
        self.pairingCode = [aDecoder decodeObjectForKey:@"session-key"];
    }

    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:self.pairingCode forKey:@"session-key"];
}

- (void) addObservers
{
    [super addObservers];

    [self addObserver:self forKeyPath:@"pairingCode" options:0 context:nil];
}

- (void)removeObservers
{
    [super removeObservers];

    [self removeObserver:self forKeyPath:@"pairingCode"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.delegate serviceConfigUpdate:self];
}

@end
