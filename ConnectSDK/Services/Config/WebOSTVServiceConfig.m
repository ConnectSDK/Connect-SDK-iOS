//
//  WebOSTVServiceConfig.m
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "WebOSTVServiceConfig.h"

@implementation WebOSTVServiceConfig

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.clientKey = [aDecoder decodeObjectForKey:@"client-key"];
        self.SSLCertificates = [aDecoder decodeObjectForKey:@"ssl-key"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.clientKey forKey:@"client-key"];
    [aCoder encodeObject:self.SSLCertificates forKey:@"ssl-key"];
}

- (void) addObservers
{
    [super addObservers];

    [self addObserver:self forKeyPath:@"clientKey" options:0 context:nil];
    [self addObserver:self forKeyPath:@"SSLCertificates" options:0 context:nil];
}

- (void) removeObservers
{
    [super removeObservers];

    [self removeObserver:self forKeyPath:@"clientKey"];
    [self removeObserver:self forKeyPath:@"SSLCertificates"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.delegate serviceConfigUpdate:self];
}

@end
