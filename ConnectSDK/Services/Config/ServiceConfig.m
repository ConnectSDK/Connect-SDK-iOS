//
//  ServiceConfig.m
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceConfig.h"

@implementation ServiceConfig

- (instancetype) initWithServiceDescription:(ServiceDescription *)serviceDescription
{
    self = [super init];
    
    if (self)
    {
        self.UUID = serviceDescription.UUID;
        self.connected = NO;
        self.wasConnected = NO;
        self.lastDetection = [NSDate date].timeIntervalSince1970;
    }
    
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    
    if (self)
    {
        self.UUID = [aDecoder decodeObjectForKey:@"UUID-key"];
        self.connected = [aDecoder decodeBoolForKey:@"connected-key"];
        self.wasConnected = [aDecoder decodeBoolForKey:@"wasConnected-key"];
        self.lastDetection = [aDecoder decodeDoubleForKey:@"lastDetection-key"];
    }
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.UUID forKey:@"UUID-key"];
    [aCoder encodeBool:self.connected forKey:@"connected-key"];
    [aCoder encodeBool:self.wasConnected forKey:@"wasConnected-key"];
    [aCoder encodeDouble:self.lastDetection forKey:@"lastDetection-key"];
}

- (void) addObservers
{
    [self addObserver:self forKeyPath:@"UUID" options:0 context:nil];
    [self addObserver:self forKeyPath:@"connected" options:0 context:nil];
    [self addObserver:self forKeyPath:@"wasConnected" options:0 context:nil];
    [self addObserver:self forKeyPath:@"lastDetection" options:0 context:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [_delegate serviceConfigUpdate:self];
}

- (void)setDelegate:(id <ServiceConfigDelegate>)delegate
{
    if (delegate == nil && _delegate != nil)
        [self removeObservers];
    else if (delegate != nil && _delegate == nil)
    {
        _delegate = delegate;
        [self addObservers];
    } else
        _delegate = delegate;
}

- (void) removeObservers
{
    @try {
        [self removeObserver:self forKeyPath:@"UUID"];
        [self removeObserver:self forKeyPath:@"connected"];
        [self removeObserver:self forKeyPath:@"wasConnected"];
        [self removeObserver:self forKeyPath:@"lastDetection"];
    }
    @catch (NSException *exception) {
        // don't need to handle this exception, because observers aren't added
    }
}

- (void) dealloc
{
    self.delegate = nil;
}

@end
