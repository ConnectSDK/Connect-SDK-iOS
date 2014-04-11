//
//  ConnectableDevice.m
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ConnectableDevice.h"
#import "DLNAService.h"
#import "MediaControl.h"
#import "ExternalInputControl.h"
#import "ToastControl.h"
#import "TextInputControl.h"

@implementation ConnectableDevice
{
    ServiceDescription *_consolidatedServiceDescription;
    NSMutableDictionary *_services;
}

@synthesize serviceDescription = _serviceDescription;
@synthesize delegate = _delegate;

- (instancetype) initWithDescription:(ServiceDescription *)description
{
    self = [super init];
    
    if (self)
    {
        _serviceDescription = description;
        _consolidatedServiceDescription = [ServiceDescription new];
        _services = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

+ (instancetype) connectableDeviceWithDescription:(ServiceDescription *)description
{
    return [[ConnectableDevice alloc] initWithDescription:description];
}

- (void) setDelegate:(id<ConnectableDeviceDelegate>)delegate
{
    _delegate = delegate;
    
    if (_delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionRequired:forService:)])
    {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, DeviceService *service, BOOL *stop) {
            if (service.isConnectable && !service.connected)
                [_delegate connectableDeviceConnectionRequired:self forService:service];
        }];
    }
}

#pragma mark - General info

- (NSString *) address
{
    return _consolidatedServiceDescription.address;
}

- (NSString *) friendlyName
{
    return _consolidatedServiceDescription.friendlyName;
}

- (NSString *) modelName
{
    return _consolidatedServiceDescription.modelName;
}

- (NSString *) modelNumber
{
    return _consolidatedServiceDescription.modelNumber;
}

- (NSString *) connectedServiceNames
{
    __block NSString *serviceNames = @"";

    if (_services.count == 0)
        return serviceNames;

    [_services enumerateKeysAndObjectsUsingBlock:^(NSString * key, DeviceService *service, BOOL *stop) {
        serviceNames = [serviceNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", key]];
    }];

    serviceNames = [serviceNames substringToIndex:serviceNames.length - 2];
    
    return serviceNames;
}

- (void) connect
{
    if (self.isConnectable)
    {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, DeviceService *service, BOOL *stop)
        {
            if (!service.connected)
                [service connect];
        }];
    } else
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceReady:)])
            dispatch_on_main(^{ [self.delegate connectableDeviceReady:self]; });
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnect) name:kConnectSDKWirelessSSIDChanged object:nil];
}

- (void) disconnect
{
    if (self.isConnectable)
    {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, DeviceService *service, BOOL *stop)
        {
            if (service.connected)
                [service disconnect];
        }];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kConnectSDKWirelessSSIDChanged object:nil];

    dispatch_on_main(^{ [self.delegate connectableDeviceDisconnected:self withError:nil]; });
}

- (BOOL) isConnectable
{
    __block BOOL connectable = NO;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, DeviceService *service, BOOL *stop)
    {
        if (service.isConnectable)
        {
            connectable = YES;
            *stop = YES;
        }
    }];

    return connectable;
}

- (int) connectedServiceCount
{
    __block int count = 0;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, DeviceService *service, BOOL *stop)
    {
        if ([service isConnectable])
        {
            if (service.connected)
                count++;
        } else
        {
            count++;
        }

    }];

    return count;
}

#pragma mark - NSCoding methods

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    if (self)
    {
        _services = [NSMutableDictionary new];

        _consolidatedServiceDescription = [[ServiceDescription alloc] init];
        _consolidatedServiceDescription.modelName = [aDecoder decodeObjectForKey:@"modelName-key"];
        _consolidatedServiceDescription.modelNumber = [aDecoder decodeObjectForKey:@"modelNumber-key"];
        _consolidatedServiceDescription.address = [aDecoder decodeObjectForKey:@"address-key"];

        NSArray *services = [aDecoder decodeObjectForKey:@"services-key"];

        [services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
        {
            [self addService:service];
        }];
    }

    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.modelName forKey:@"modelName-key"];
    [aCoder encodeObject:self.modelNumber forKey:@"modelNumber-key"];
    [aCoder encodeObject:self.address forKey:@"address-key"];
    [aCoder encodeObject:self.services forKey:@"services-key"];
}

#pragma mark - Service management

- (NSArray *) services
{
    return [_services allValues];
}

- (BOOL) hasServices
{
    return _services.count > 0;
}

- (void) addService:(DeviceService *)service
{
    DeviceService *existingService = [_services objectForKey:service.serviceName];
    
    if (existingService)
        return;
    
    NSArray *oldCapabilities = self.capabilities;
    
    [_services setObject:service forKey:service.serviceName];
    service.delegate = self;
    
    if (service.isConnectable && !service.connected)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionRequired:forService:)])
            dispatch_on_main(^{ [_delegate connectableDeviceConnectionRequired:self forService:service]; });
    }
    
    [self updateCapabilitiesList:oldCapabilities];
    
    [self updateConsolidatedServiceDescription:service.serviceDescription];
}

- (void) removeServiceWithId:(NSString *)serviceId
{
    DeviceService *service = [_services objectForKey:serviceId];
    
    if (service == nil)
        return;
    
    NSArray *oldCapabilities = self.capabilities;
    
    [service disconnect];
    
    [_services removeObjectForKey:serviceId];
    
    [self updateCapabilitiesList:oldCapabilities];
}

- (void) updateCapabilitiesList:(NSArray *)oldCapabilities
{
    NSArray *newCapabilities = self.capabilities;
    
    NSMutableArray *removedCapabilities = [NSMutableArray new];
    
    [oldCapabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop) {
        if (![newCapabilities containsObject:capability])
            [removedCapabilities addObject:capability];
    }];
    
    NSMutableArray *addedCapabilities = [NSMutableArray new];
    
    [newCapabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop) {
        if (![oldCapabilities containsObject:capability])
            [addedCapabilities addObject:capability];
    }];
    
    NSArray *added = [NSArray arrayWithArray:addedCapabilities];
    NSArray *removed = [NSArray arrayWithArray:removedCapabilities];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:capabilitiesAdded:removed:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self capabilitiesAdded:added removed:removed]; });
}

- (void) updateConsolidatedServiceDescription:(ServiceDescription *)serviceDescription
{
    if (serviceDescription.address)
        _consolidatedServiceDescription.address = serviceDescription.address;
    
    if (serviceDescription.friendlyName)
        _consolidatedServiceDescription.friendlyName = serviceDescription.friendlyName;
    
    if (serviceDescription.modelName)
        _consolidatedServiceDescription.modelName = serviceDescription.modelName;
    
    if (serviceDescription.modelNumber)
        _consolidatedServiceDescription.modelNumber = serviceDescription.modelNumber;
}

- (DeviceService *)serviceWithName:(NSString *)serviceName
{
    __block DeviceService *foundService;

    [_services enumerateKeysAndObjectsUsingBlock:^(NSString *name, DeviceService *service, BOOL *stop)
    {
        if ([name isEqualToString:serviceName])
        {
            foundService = service;
            *stop = YES;
        }
    }];

    return foundService;
}

#pragma mark - DeviceServiceDelegate
#pragma mark Connection

- (void)deviceServiceConnectionRequired:(DeviceService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionRequired:forService:)])
        dispatch_on_main(^{ [self.delegate connectableDeviceConnectionRequired:self forService:service]; });
}

- (void)deviceServiceConnectionSuccess:(DeviceService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionSuccess:forService:)])
        dispatch_on_main(^{ [self.delegate connectableDeviceConnectionSuccess:self forService:service]; });

    if (self.connectedServiceCount == _services.count)
    {
        dispatch_on_main(^{ [self.delegate connectableDeviceReady:self]; });
    }
}

- (void)deviceService:(DeviceService *)service didFailConnectWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:connectionFailedWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self connectionFailedWithError:error]; });

    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:didFailConnectWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service didFailConnectWithError:error]; });
}

- (void)deviceService:(DeviceService *)service disconnectedWithError:(NSError *)error
{
    // TODO: need to aggregate errors between disconnects
    if (_services.count == 0)
        dispatch_on_main(^{ [self.delegate connectableDeviceDisconnected:self withError:error]; });

    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service disconnectedWithError:error]; });
}

#pragma mark Pairing

- (void)deviceService:(DeviceService *)service pairingRequiredOfType:(DeviceServicePairingType)pairingType withData:(id)pairingData
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:pairingRequiredOfType:withData:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service pairingRequiredOfType:pairingType withData:pairingData]; });
}

- (void)deviceServicePairingSuccess:(DeviceService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevicePairingSuccess:service:)])
        dispatch_on_main(^{ [self.delegate connectableDevicePairingSuccess:self service:service]; });
}

- (void)deviceService:(DeviceService *)service pairingFailedWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:pairingFailedWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service pairingFailedWithError:error]; });
}

#pragma mark - Capabilities

- (NSArray *) capabilities
{
    NSMutableArray *caps = [NSMutableArray new];

    [self.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
    {
        [service.capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger capabilityIdx, BOOL *capabilityStop)
        {
            if (![caps containsObject:capability])
                [caps addObject:capability];
        }];
    }];

    return [NSArray arrayWithArray:caps];
}

- (BOOL) hasCapability:(NSString *)capability
{
    __block BOOL hasCap = NO;

    [self.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
    {
        if ([service hasCapability:capability])
        {
            hasCap = YES;
            *stop = YES;
        }
    }];

    return hasCap;
}

- (BOOL) hasCapabilities:(NSArray *)capabilities
{
    __block BOOL hasCaps = YES;
    NSArray *myCapabilities = [self capabilities];

    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (![myCapabilities containsObject:capability])
        {
            hasCaps = NO;
            *stop = YES;
        }
    }];

    return hasCaps;
}

- (BOOL) hasAnyCapability:(NSArray *)capabilities
{
    __block BOOL hasCap = NO;

    [self.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
    {
        if ([service hasAnyCapability:capabilities])
        {
            hasCap = YES;
            *stop = YES;
        }
    }];

    return hasCap;
}

- (id<Launcher>) launcher
{
    __block id<Launcher> foundLauncher;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(launcher)])
            return;
        
        id<Launcher> launcher = [service launcher];
        
        if (launcher)
        {
            if (foundLauncher)
            {
                if (launcher.launcherPriority > foundLauncher.launcherPriority)
                {
                    foundLauncher = launcher;
                }
            } else
            {
                foundLauncher = launcher;
            }
        }
    }];

    return foundLauncher;
}

- (id<ExternalInputControl>)externalInputControl
{
    __block id<ExternalInputControl> foundExternalInputControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(externalInputControl)])
            return;

        id<ExternalInputControl> externalInputControl = [service externalInputControl];

        if (externalInputControl)
        {
            if (foundExternalInputControl)
            {
                if (externalInputControl.externalInputControlPriority > foundExternalInputControl.externalInputControlPriority)
                {
                    foundExternalInputControl = externalInputControl;
                }
            } else
            {
                foundExternalInputControl = externalInputControl;
            }
        }
    }];

    return foundExternalInputControl;
}

- (id<MediaPlayer>) mediaPlayer
{
    __block id<MediaPlayer> foundPlayer;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(mediaPlayer)])
            return;

        id<MediaPlayer> player = [service mediaPlayer];

        if (player)
        {
            if (foundPlayer)
            {
                if (player.mediaPlayerPriority > foundPlayer.mediaPlayerPriority)
                {
                    foundPlayer = player;
                }
            } else
            {
                foundPlayer = player;
            }
        }
    }];

    return foundPlayer;
}

- (id<MediaControl>) mediaControl
{
    __block id<MediaControl> foundMediaControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(mediaControl)])
            return;

        id<MediaControl> mediaControl = [service mediaControl];

        if (mediaControl)
        {
            if (foundMediaControl)
            {
                if (mediaControl.mediaControlPriority > foundMediaControl.mediaControlPriority)
                {
                    foundMediaControl = mediaControl;
                }
            } else
            {
                foundMediaControl = mediaControl;
            }
        }
    }];

    return foundMediaControl;
}

- (id<VolumeControl>)volumeControl
{
    __block id<VolumeControl> foundVolume;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(volumeControl)])
            return;

        id<VolumeControl> volume = [service volumeControl];

        if (volume)
        {
            if (foundVolume)
            {
                if (volume.volumeControlPriority > foundVolume.volumeControlPriority)
                {
                    foundVolume = volume;
                }
            } else
            {
                foundVolume = volume;
            }
        }
    }];

    return foundVolume;
}

- (id<TVControl>)tvControl
{
    __block id<TVControl> foundTV;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(tvControl)])
            return;

        id<TVControl> tv = [service tvControl];

        if (tv)
        {
            if (foundTV)
            {
                if (tv.tvControlPriority > foundTV.tvControlPriority)
                {
                    foundTV = tv;
                }
            } else
            {
                foundTV = tv;
            }
        }
    }];

    return foundTV;
}

- (id<KeyControl>) keyControl
{
    __block id<KeyControl> foundKeyControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(keyControl)])
            return;

        id<KeyControl> keyControl = [service keyControl];

        if (keyControl)
        {
            if (foundKeyControl)
            {
                if (keyControl.keyControlPriority > foundKeyControl.keyControlPriority)
                {
                    foundKeyControl = keyControl;
                }
            } else
            {
                foundKeyControl = keyControl;
            }
        }
    }];

    return foundKeyControl;
}

- (id<TextInputControl>) textInputControl
{
    __block id<TextInputControl> foundTextInput;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(textInputControl)])
            return;

        id<TextInputControl> textInput = [service textInputControl];

        if (textInput)
        {
            if (foundTextInput)
            {
                if (textInput.textInputControlPriority > foundTextInput.textInputControlPriority)
                {
                    foundTextInput = textInput;
                }
            } else
            {
                foundTextInput = textInput;
            }
        }
    }];

    return foundTextInput;
}

- (id<MouseControl>)mouseControl
{
    __block id<MouseControl> foundMouse;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(mouseControl)])
            return;

        id<MouseControl> mouse = [service mouseControl];

        if (mouse)
        {
            if (foundMouse)
            {
                if (mouse.mouseControlPriority > foundMouse.mouseControlPriority)
                {
                    foundMouse = mouse;
                }
            } else
            {
                foundMouse = mouse;
            }
        }
    }];

    return foundMouse;
}

- (id<PowerControl>)powerControl
{
    __block id<PowerControl> foundPower;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(powerControl)])
            return;

        id<PowerControl> power = [service powerControl];

        if (power)
        {
            if (foundPower)
            {
                if (power.powerControlPriority > foundPower.powerControlPriority)
                {
                    foundPower = power;
                }
            } else
            {
                foundPower = power;
            }
        }
    }];

    return foundPower;
}

- (id<ToastControl>) toastControl
{
    __block id<ToastControl> foundToastControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(toastControl)])
            return;

        id<ToastControl> toastControl = [service toastControl];

        if (toastControl)
        {
            if (foundToastControl)
            {
                if (toastControl.toastControlPriority > foundToastControl.toastControlPriority)
                {
                    foundToastControl = toastControl;
                }
            } else
            {
                foundToastControl = toastControl;
            }
        }
    }];

    return foundToastControl;
}

- (id<WebAppLauncher>) webAppLauncher
{
    __block id<WebAppLauncher> foundWebAppLauncher;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(webAppLauncher)])
            return;

        id<WebAppLauncher> webAppLauncher = [service webAppLauncher];

        if (webAppLauncher)
        {
            if (foundWebAppLauncher)
            {
                if (webAppLauncher.webAppLauncherPriority > foundWebAppLauncher.webAppLauncherPriority)
                {
                    foundWebAppLauncher = webAppLauncher;
                }
            } else
            {
                foundWebAppLauncher = webAppLauncher;
            }
        }
    }];

    return foundWebAppLauncher;
}

@end
