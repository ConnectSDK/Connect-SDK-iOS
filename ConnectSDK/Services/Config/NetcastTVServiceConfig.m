//
// Created by Jeremy White on 12/30/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "NetcastTVServiceConfig.h"


@implementation NetcastTVServiceConfig

- (instancetype) initWithJSONObject:(NSDictionary *)dict
{
    self = [super init];

    if (self)
    {
        self.pairingCode = dict[@"pairingCode"];
    }

    return self;
}

- (NSDictionary *) toJSONObject
{
    NSDictionary *superDictionary = [super toJSONObject];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:superDictionary];

    dictionary[@"class"] = NSStringFromClass([self class]);

    if (self.pairingCode) dictionary[@"pairingCode"] = self.pairingCode;

    return [NSDictionary dictionaryWithDictionary:dictionary];
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
