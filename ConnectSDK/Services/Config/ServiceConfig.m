//
//  ServiceConfig.m
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
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

#import "ServiceConfig.h"

@implementation ServiceConfig
{
    BOOL _hasObservers;
}

+ (instancetype) serviceConfigWithJSONObject:(NSDictionary *)dictionary
{
    NSString *configClassName = dictionary[@"class"];
    Class configClass = NSClassFromString(configClassName);

    ServiceConfig *serviceConfig = [[configClass alloc] initWithJSONObject:dictionary];
    return serviceConfig;
}

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super init];

    if (self)
    {
        self.UUID = serviceConfig.UUID;
        self.connected = serviceConfig.connected;
        self.wasConnected = serviceConfig.wasConnected;
        self.lastDetection = serviceConfig.lastDetection;

        self.delegate = serviceConfig.delegate;
        serviceConfig.delegate = nil;
    }

    return self;
}

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

- (void) addObservers
{
    if (_hasObservers)
        return;

    [self addObserver:self forKeyPath:@"UUID" options:0 context:nil];
    [self addObserver:self forKeyPath:@"connected" options:0 context:nil];
    [self addObserver:self forKeyPath:@"wasConnected" options:0 context:nil];
    [self addObserver:self forKeyPath:@"lastDetection" options:0 context:nil];

    _hasObservers = YES;
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
    if (!_hasObservers)
        return;

    @try {
        [self removeObserver:self forKeyPath:@"UUID"];
        [self removeObserver:self forKeyPath:@"connected"];
        [self removeObserver:self forKeyPath:@"wasConnected"];
        [self removeObserver:self forKeyPath:@"lastDetection"];
    }
    @catch (NSException *exception) {
        // don't need to handle this exception, because observers aren't added
    }

    _hasObservers = NO;
}

- (void) dealloc
{
    self.delegate = nil;
}

#pragma mark - JSONObjectCoding methods

- (instancetype) initWithJSONObject:(NSDictionary *)dictionary
{
    self = [super init];

    if (self)
    {
        self.UUID = [dictionary objectForKey:@"UUID"];
        self.connected = [[dictionary objectForKey:@"connected"] boolValue];
        self.wasConnected = [[dictionary objectForKey:@"wasConnected"] boolValue];
        self.lastDetection = [[dictionary objectForKey:@"lastDetection"] doubleValue];

        if (self.connected)
        {
            self.connected = NO;
            self.wasConnected = YES;
        }
    }

    return self;
}

- (NSDictionary *) toJSONObject
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    dictionary[@"class"] = NSStringFromClass([self class]);

    if (self.UUID) dictionary[@"UUID"] = self.UUID;
    if (self.connected) dictionary[@"connected"] = @(self.connected);
    if (self.wasConnected) dictionary[@"wasConnected"] = @(self.wasConnected);
    if (self.lastDetection) dictionary[@"lastDetection"] = @(self.lastDetection);

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
