//
//  DeviceService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/5/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DeviceService.h"
#import "Launcher.h"
#import "MediaPlayer.h"
#import "ExternalInputControl.h"
#import "WebAppLauncher.h"
#import "ConnectError.h"

@implementation DeviceService

- (NSString *)serviceName
{
    return self.serviceDescription.serviceId;
}

+ (NSDictionary *) discoveryParameters { return nil; }

+ (instancetype) deviceServiceWithClass:(Class)class serviceConfig:(ServiceConfig *)serviceConfig
{
    return [[class alloc] initWithServiceConfig:serviceConfig];
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        self.connected = NO;
    }

    return self;
}

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [self init];

    if (self)
    {
        self.serviceConfig = serviceConfig;
    }

    return self;
}

#pragma mark - Capabilities

- (NSArray *) capabilities { return [NSArray array]; }

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

#pragma mark - NSCoding methods

- (id) initWithCoder:(NSCoder *)aDecoder
{
    ServiceConfig *serviceConfig = [aDecoder decodeObjectForKey:@"serviceConfig-key"];

    self = [DeviceService deviceServiceWithClass:[DeviceService class] serviceConfig:serviceConfig];

    if (self)
    {
        self.serviceDescription = [aDecoder decodeObjectForKey:@"serviceDescription-key"];
    }

    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.serviceConfig forKey:@"serviceConfig-key"];
    [aCoder encodeObject:self.serviceDescription forKey:@"serviceDescription-key"];
}

@end
