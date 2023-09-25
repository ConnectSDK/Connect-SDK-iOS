//
//  DeviceService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/5/13.
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

#import "DeviceService.h"
#import "Launcher.h"
#import "MediaPlayer.h"
#import "ExternalInputControl.h"
#import "WebAppLauncher.h"
#import "ConnectError.h"

@implementation DeviceService
{
    NSMutableArray *_capabilities;
}

- (NSString *)serviceName
{
    return self.serviceDescription.serviceId;
}

+ (NSDictionary *) discoveryParameters { return nil; }

+ (instancetype) deviceServiceWithClass:(Class)_class serviceConfig:(ServiceConfig *)serviceConfig
{
    return [[_class alloc] initWithServiceConfig:serviceConfig];
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _connected = NO;
        _capabilities = [NSMutableArray new];

        [self updateCapabilities];
    }

    return self;
}

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [self init];

    if (self)
    {
        _serviceConfig = serviceConfig;
    }

    return self;
}

static BOOL _shouldDisconnectOnBackground = YES;

+ (BOOL) shouldDisconnectOnBackground
{
    return _shouldDisconnectOnBackground;
}

+ (void) setShouldDisconnectOnBackround:(BOOL)shouldDisconnectOnBackground
{
    _shouldDisconnectOnBackground = shouldDisconnectOnBackground;
}

#pragma mark - Capabilities

- (NSArray *) capabilities { return [NSArray arrayWithArray:_capabilities]; }

- (BOOL) hasCapability:(NSString *)capability
{
    NSRange anyRange = [capability rangeOfString:@".Any"];
    
    if (anyRange.location != NSNotFound)
    {
        NSString *matchedCapability = [capability substringToIndex:anyRange.location];

        __block BOOL hasCap = NO;

        [self.capabilities enumerateObjectsUsingBlock:^(NSString *item, NSUInteger idx, BOOL *stop)
        {
            if ([item rangeOfString:matchedCapability].location != NSNotFound)
            {
                hasCap = YES;
                *stop = YES;
            }
        }];

        return hasCap;
    }

    return [self.capabilities containsObject:capability];
}

- (BOOL) hasCapabilities:(NSArray *)capabilities
{
    __block BOOL hasCaps = YES;

    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (![self hasCapability:capability])
        {
            hasCaps = NO;
            *stop = YES;
        }
    }];

    return hasCaps;
}

- (BOOL) hasAnyCapability:(NSArray *)capabilities
{
    __block BOOL hasAnyCap = NO;

    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if ([self hasCapability:capability])
        {
            hasAnyCap = YES;
            *stop = YES;
        }
    }];

    return hasAnyCap;
}

- (void) updateCapabilities { }

- (void) setCapabilities:(NSArray *)newCapabilities
{
    NSArray *oldCapabilities = _capabilities;

    _capabilities = [NSMutableArray arrayWithArray:newCapabilities];

    NSMutableArray *lostCapabilities = [NSMutableArray new];

    [oldCapabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (![newCapabilities containsObject:capability])
            [lostCapabilities addObject:capability];
    }];

    NSMutableArray *addedCapabilities = [NSMutableArray new];

    [newCapabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (![oldCapabilities containsObject:capability])
            [addedCapabilities addObject:capability];
    }];

    if (_delegate && [_delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        dispatch_on_main(^{ [_delegate deviceService:self capabilitiesAdded:addedCapabilities removed:lostCapabilities]; });
}

- (void) addCapability:(NSString *)capability
{
    if (!capability || capability.length == 0)
        return;

    if ([self hasCapability:capability])
        return;

    [_capabilities addObject:capability];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:@[capability] removed:[NSArray array]];
}

- (void) addCapabilities:(NSArray *)capabilities
{
    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (!capability || capability.length == 0)
            return;

        if ([self hasCapability:capability])
            return;

        [_capabilities addObject:capability];
    }];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:capabilities removed:[NSArray array]];
}

- (void) removeCapability:(NSString *)capability
{
    if (!capability || capability.length == 0)
        return;

    if (![self hasCapability:capability])
        return;

    do
    {
        [_capabilities removeObject:capability];
    } while ([_capabilities containsObject:capability]);

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:[NSArray array] removed:@[capability]];
}

- (void) removeCapabilities:(NSArray *)capabilities
{
    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (!capability || capability.length == 0)
            return;

        if (![self hasCapability:capability])
            return;

        do
        {
            [_capabilities removeObject:capability];
        } while ([_capabilities containsObject:capability]);
    }];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:capabilitiesAdded:removed:)])
        [self.delegate deviceService:self capabilitiesAdded:[NSArray array] removed:capabilities];
}

#pragma mark - Connection

- (BOOL) isConnectable
{
    return NO;
}

- (void) connect { }
- (void) disconnect { }

# pragma mark - Pairing

- (BOOL) requiresPairing
{
    return self.pairingType != DeviceServicePairingTypeNone;
}

- (DeviceServicePairingType) pairingType
{
    return DeviceServicePairingTypeNone;
}

- (void) setPairingType:(DeviceServicePairingType)pairingType {
    //Subclasses should implement this method to set pairing type.
}

- (id) pairingData
{
    return nil;
}

- (void)pairWithData:(id)pairingData { }

#pragma mark - Utility

void dispatch_on_main(dispatch_block_t block) {
    if (block)
        dispatch_async(dispatch_get_main_queue(), block);
}

id ensureString(id value)
{
    return value != nil ? value : @"";
}

- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provice a valid LaunchSession object"]);

        return;
    }

    if (!launchSession.service)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"This LaunchSession does not have an associated DeviceService"]);

        return;
    }

    switch (launchSession.sessionType)
    {
        case LaunchSessionTypeApp:
            if ([launchSession.service conformsToProtocol:@protocol(Launcher)])
                [((id <Launcher>) launchSession.service) closeApp:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeMedia:
            if ([launchSession.service conformsToProtocol:@protocol(MediaPlayer)])
                [((id <MediaPlayer>) launchSession.service) closeMedia:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeExternalInputPicker:
            if ([launchSession.service conformsToProtocol:@protocol(ExternalInputControl)])
                [((id <ExternalInputControl>) launchSession.service) closeInputPicker:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeWebApp:
            if ([launchSession.service conformsToProtocol:@protocol(WebAppLauncher)])
                [((id <WebAppLauncher>) launchSession.service) closeWebApp:launchSession success:success failure:failure];
            break;

        case LaunchSessionTypeUnknown:
        default:
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"This DeviceService does not know how to close this LaunchSession"]);
    }
}

#pragma mark - JSONObjectCoding methods

+ (instancetype) deviceServiceWithJSONObject:(NSDictionary *)dict
{
    NSString *className = dict[@"class"];

    if (!className || className.length == 0 || [className isKindOfClass:[NSNull class]])
        return nil;

    Class DeviceServiceClass = NSClassFromString(className);

    if (!DeviceServiceClass)
        return nil;

    return [[DeviceServiceClass alloc] initWithJSONObject:dict];
}

- (instancetype) initWithJSONObject:(NSDictionary *)dict
{
    NSDictionary *configDictionary = dict[@"config"];
    ServiceConfig *config;

    if (configDictionary)
        config = [ServiceConfig serviceConfigWithJSONObject:configDictionary];

    if (config)
        self = [self initWithServiceConfig:config];
    else
        self = [self init];

    if (self)
    {
        NSDictionary *descriptionDictionary = dict[@"description"];

        if (descriptionDictionary)
            self.serviceDescription = [[ServiceDescription alloc] initWithJSONObject:descriptionDictionary];
    }

    return self;
}

- (NSDictionary *) toJSONObject
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    dictionary[@"class"] = NSStringFromClass([self class]);

    if (self.serviceConfig)
        dictionary[@"config"] = [self.serviceConfig toJSONObject];

    if (self.serviceDescription)
        dictionary[@"description"] = [self.serviceDescription toJSONObject];

    return dictionary;
}

@end
