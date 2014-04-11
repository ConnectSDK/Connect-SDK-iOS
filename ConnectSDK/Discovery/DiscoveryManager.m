//
//  DiscoveryManager.m
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DiscoveryManager.h"

#import "DiscoveryProviderDelegate.h"
#import "DiscoveryProvider.h"

#import "CastDiscoveryProvider.h"
#import "SSDPDiscoveryProvider.h"

#import "CastService.h"
#import "DIALService.h"
#import "DLNAService.h"
#import "NetcastTVService.h"
#import "RokuService.h"
#import "WebOSTVService.h"

#import "ConnectableDevice.h"
#import "DefaultConnectableDeviceStore.h"
#import "ServiceDescription.h"
#import "ServiceConfig.h"
#import "ServiceConfigDelegate.h"
#import "CapabilityFilter.h"

#import <SystemConfiguration/CaptiveNetwork.h>

@interface DiscoveryManager() <DiscoveryProviderDelegate, ServiceConfigDelegate>

@end

@implementation DiscoveryManager
{
    NSMutableDictionary *_allDevices;
    NSMutableDictionary *_compatibleDevices;

    NSMutableArray *_discoveryProviders;
    NSMutableDictionary *_deviceClasses;
    
    BOOL _shouldResumeSearch;
    BOOL _searching;
    
    DevicePicker *_currentPicker;

    NSTimer *_ssidTimer;
    NSString *_currentSSID;
}

@synthesize pairingLevel = _pairingLevel;
@synthesize useDeviceStore = _useDeviceStore;

+ (DiscoveryManager *) _sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id _sharedManager = nil;

    dispatch_once(&predicate, ^{
        _sharedManager = [[self alloc] init];
    });

    return _sharedManager;
}

+ (DiscoveryManager *) sharedManager
{
    DiscoveryManager *manager = [self _sharedManager];

    if (!manager.deviceStore)
        [manager setDeviceStore:[DefaultConnectableDeviceStore new]];

    return manager;
}

+ (DiscoveryManager *) sharedManagerWithDeviceStore:(id <ConnectableDeviceStore>)deviceStore
{
    DiscoveryManager *manager = [self _sharedManager];

    if (manager.deviceStore != deviceStore)
        [manager setDeviceStore:deviceStore];

    return manager;
}

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        _shouldResumeSearch = NO;
        _searching = NO;
        _useDeviceStore = YES;
        
        _discoveryProviders = [[NSMutableArray alloc] init];
        _deviceClasses = [[NSMutableDictionary alloc] init];

        _allDevices = [[NSMutableDictionary alloc] init];
        _compatibleDevices = [[NSMutableDictionary alloc] init];

        [self startSSIDTimer];
    }
    
    return self;
}

#pragma mark - Setup & Registration

- (void) registerDefaultServices
{
    [NSKeyedUnarchiver setClass:[NetcastTVServiceConfig class] forClassName:@"NetcastTVServiceConfig"];
    [NSKeyedUnarchiver setClass:[WebOSTVServiceConfig class] forClassName:@"WebOSTVServiceConfig"];
    
    [self registerDeviceService:[CastService class] withDiscovery:[CastDiscoveryProvider class]];
    [self registerDeviceService:[DIALService class] withDiscovery:[SSDPDiscoveryProvider class]];
    [self registerDeviceService:[RokuService class] withDiscovery:[SSDPDiscoveryProvider  class]];
    [self registerDeviceService:[DLNAService class] withDiscovery:[SSDPDiscoveryProvider class]]; // includes Netcast
    [self registerDeviceService:[WebOSTVService class] withDiscovery:[SSDPDiscoveryProvider class]];
}

- (void) registerDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass
{
    if (![discoveryClass isSubclassOfClass:[DiscoveryProvider class]])
        return;
    
    if (![deviceClass isSubclassOfClass:[DeviceService class]])
        return;
    
    __block DiscoveryProvider *discoveryProvider;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj class] isSubclassOfClass:discoveryClass])
        {
            discoveryProvider = obj;
            *stop = YES;
        }
    }];
    
    if (discoveryProvider == nil)
    {
        discoveryProvider = [[discoveryClass alloc] init];
        discoveryProvider.delegate = self;
        [_discoveryProviders addObject:discoveryProvider];
    }
    
    NSDictionary *discoveryParameters = [deviceClass discoveryParameters];
    
    NSString *serviceId = [discoveryParameters objectForKey:@"serviceId"];
    [_deviceClasses setObject:deviceClass forKey:serviceId];
    
    [discoveryProvider addDeviceFilter:discoveryParameters];
}

- (void) unregisterDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass
{
    if (![discoveryClass isSubclassOfClass:[DiscoveryProvider class]])
        return;
    
    if (![deviceClass isSubclassOfClass:[DeviceService class]])
        return;
    
    __block DiscoveryProvider *discoveryProvider;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj class] isSubclassOfClass:discoveryClass])
        {
            discoveryProvider = obj;
            *stop = YES;
        }
    }];
    
    if (discoveryProvider == nil)
        return;
    
    NSDictionary *discoveryParameters = [discoveryClass discoveryParameters];
    
    NSString *serviceId = [discoveryParameters objectForKey:@"serviceId"];
    [_deviceClasses removeObjectForKey:serviceId];
    
    [discoveryProvider removeDeviceFilter:discoveryParameters];
    
    if ([discoveryProvider isEmpty])
    {
        [discoveryProvider stopDiscovery];
        discoveryProvider.delegate = nil;
        [_discoveryProviders removeObject:discoveryProvider];
    }
}

#pragma mark - Wireless SSID Change Detection

- (void) startSSIDTimer
{
    _ssidTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(detectSSIDChange) userInfo:nil repeats:YES];
    [_ssidTimer fire];
}

- (void) stopSSIDTimer
{
    [_ssidTimer invalidate];
    _ssidTimer = nil;
}

- (void) detectSSIDChange
{
    NSArray *interfaces = (__bridge_transfer id) CNCopySupportedInterfaces();

    __block NSString *ssidName;

    [interfaces enumerateObjectsUsingBlock:^(NSString *interface, NSUInteger idx, BOOL *stop)
    {
        if ([interface caseInsensitiveCompare:@"en0"] != NSOrderedSame)
            return;

        NSDictionary *info = (__bridge_transfer id) CNCopyCurrentNetworkInfo ((__bridge CFStringRef) interface);

        if (info && [info objectForKey:@"SSID"])
        {
            ssidName = [info objectForKey:@"SSID"];
            *stop = YES;
        }
    }];

    if (ssidName == nil)
        ssidName = @"";

    if ([ssidName caseInsensitiveCompare:_currentSSID] != NSOrderedSame)
    {
        if (_currentSSID != nil)
        {
            [self purgeDeviceList];

            [[NSNotificationCenter defaultCenter] postNotificationName:kConnectSDKWirelessSSIDChanged object:nil];
        }

        _currentSSID = ssidName;
    }
}

- (void) purgeDeviceList
{
    [self.compatibleDevices enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *stop)
    {
        [device disconnect];

        if (self.delegate)
            [self.delegate discoveryManager:self didLoseDevice:device];

        if (self.devicePicker)
            [self.devicePicker discoveryManager:self didLoseDevice:device];
    }];

    _allDevices = [NSMutableDictionary new];
    _compatibleDevices = [NSMutableDictionary new];
}

#pragma mark - Capability Filtering

- (void)setCapabilityFilters:(NSArray *)capabilityFilters
{
    _capabilityFilters = capabilityFilters;

    [_compatibleDevices enumerateKeysAndObjectsUsingBlock:^(NSString *address, ConnectableDevice *device, BOOL *stop)
    {
        if (self.delegate)
            [self.delegate discoveryManager:self didLoseDevice:device];
    }];

    _compatibleDevices = [[NSMutableDictionary alloc] init];

    [[_allDevices allValues] enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop)
    {
        if ([self deviceIsCompatible:device])
        {
            [_compatibleDevices setValue:device forKey:device.address];

            if (self.delegate)
                [self.delegate discoveryManager:self didFindDevice:device];
        }
    }];
}

- (BOOL) descriptionIsNetcastTV:(ServiceDescription *)description
{
    BOOL isNetcast = NO;

    if ([description.modelName.uppercaseString isEqualToString:@"LG TV"])
    {
        if ([description.modelDescription.uppercaseString rangeOfString:@"WEBOS"].location == NSNotFound)
        {
            isNetcast = YES;
        }
    }

    return isNetcast;
}

#pragma mark - Device lists

- (NSDictionary *) allDevices
{
    return [NSDictionary dictionaryWithDictionary:_allDevices];
}

- (NSDictionary *)compatibleDevices
{
    return [NSDictionary dictionaryWithDictionary:_compatibleDevices];
}

- (BOOL) deviceIsCompatible:(ConnectableDevice *)device
{
    if (!_capabilityFilters || _capabilityFilters.count == 0)
        return YES;

    __block BOOL isCompatible = NO;

    [self.capabilityFilters enumerateObjectsUsingBlock:^(CapabilityFilter *filter, NSUInteger idx, BOOL *stop)
    {
        if ([device hasCapabilities:filter.capabilities])
        {
            isCompatible = YES;
            *stop = YES;
        }
    }];

    return isCompatible;
}

- (void) handleDeviceAdd:(ConnectableDevice *)device
{
    [self.deviceStore addDevice:device];

    if (![self deviceIsCompatible:device])
        return;

    [_compatibleDevices setValue:device forKey:device.address];

    if (self.delegate)
        [self.delegate discoveryManager:self didFindDevice:device];

    if (_currentPicker)
        [_currentPicker discoveryManager:self didFindDevice:device];
}

- (void) handleDeviceUpdate:(ConnectableDevice *)device
{
    [self.deviceStore updateDevice:device];

    if ([self deviceIsCompatible:device])
    {
        if ([_compatibleDevices objectForKey:device.address])
        {
            if (self.delegate)
                [self.delegate discoveryManager:self didUpdateDevice:device];

            if (_currentPicker)
                [_currentPicker discoveryManager:self didUpdateDevice:device];
        } else
        {
            [self handleDeviceAdd:device];
        }
    } else
    {
        [_compatibleDevices removeObjectForKey:device.address];
        [self handleDeviceLoss:device];
    }
}

- (void) handleDeviceLoss:(ConnectableDevice *)device
{
    if (self.delegate)
        [self.delegate discoveryManager:self didLoseDevice:device];

    if (_currentPicker)
        [_currentPicker discoveryManager:self didLoseDevice:device];
}

- (void)setPairingLevel:(ConnectableDevicePairingLevel)pairingLevel
{
    NSAssert(!_searching, @"Cannot change pairing level while DiscoveryManager is running.");

    _pairingLevel = pairingLevel;
}

#pragma mark - Control

- (void) startDiscovery
{
    if (_searching)
        return;

    if (_deviceClasses.count == 0)
        [self registerDefaultServices];

    _searching = YES;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *service, NSUInteger idx, BOOL *stop) {
        [service startDiscovery];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hAppDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hAppDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) stopDiscovery
{
    if (!_searching)
        return;

    _searching = NO;
    
    [_discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *service, NSUInteger idx, BOOL *stop) {
        [service stopDiscovery];
    }];
    
    if (!_shouldResumeSearch)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }
}

#pragma mark - DiscoveryProviderDelegate methods

- (void)discoveryProvider:(DiscoveryProvider *)provider didFindService:(ServiceDescription *)description
{
    NSLog(@"DiscoveryManager::discoveryProvider::didFindService %@ (%@)", description.friendlyName, description.serviceId);
    
    BOOL deviceIsNew = NO;
    ConnectableDevice *device = [_allDevices objectForKey:description.address];
    
    if (device == nil)
    {
        device = [ConnectableDevice connectableDeviceWithDescription:description];
        [_allDevices setObject:device forKey:description.address];
        deviceIsNew = YES;
    }

    Class deviceServiceClass;

    if ([self descriptionIsNetcastTV:description])
    {
        deviceServiceClass = [NetcastTVService class];
        description.serviceId = [[NetcastTVService discoveryParameters] objectForKey:@"serviceId"];
    } else
    {
        deviceServiceClass = [_deviceClasses objectForKey:description.serviceId];
    }

    // Prevent non-LG TV DLNA devices from being picked up
    if (deviceServiceClass == [DLNAService class])
    {
        NSRange rangeOfNetcast = [description.locationXML.lowercaseString rangeOfString:@"netcast"];
        NSRange rangeOfWebOS = [description.locationXML.lowercaseString rangeOfString:@"webos"];

        if (rangeOfNetcast.location == NSNotFound && rangeOfWebOS.location == NSNotFound)
            return;
    }

    ServiceConfig *serviceConfig;

    if (self.useDeviceStore)
    {
        serviceConfig = [self lookupMatchServiceConfigFromDeviceStore:description.UUID];
        serviceConfig.delegate = self;
        serviceConfig.lastDetection = [NSDate date].timeIntervalSince1970;
    }

    BOOL newServiceConfig = serviceConfig == nil;

    if (newServiceConfig)
    {
        serviceConfig = [[ServiceConfig alloc] initWithServiceDescription:description];
        serviceConfig.delegate = self;
    }
    
    __block BOOL deviceAlreadyHasService = NO;
    
    [device.services enumerateObjectsUsingBlock:^(DeviceService *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.serviceDescription.serviceId isEqualToString:description.serviceId])
        {
            deviceAlreadyHasService = YES;
            *stop = YES;
        }
    }];
    
    if (deviceAlreadyHasService)
        return;
    
    DeviceService *deviceService = [DeviceService deviceServiceWithClass:deviceServiceClass serviceConfig:serviceConfig];
    deviceService.serviceDescription = description;
    [device addService:deviceService];

    if (deviceIsNew)
        [self handleDeviceAdd:device];
    else
        [self handleDeviceUpdate:device];
}

- (void)discoveryProvider:(DiscoveryProvider *)provider didLoseService:(ServiceDescription *)description
{
    NSLog(@"DiscoveryManager::discoveryProvider::didLoseService %@ (%@)", description.friendlyName, description.serviceId);
    
    ConnectableDevice *device = [_allDevices objectForKey:description.address];
    
    if (device)
    {
        NSLog(@"DiscoveryManager::discoveryProvider::didLoseService removed service from device at address %@", description.address);
        
        [device removeServiceWithId:description.serviceId];

        if (![device hasServices])
        {
            NSLog(@"DiscoveryManager::discoveryProvider::didLoseService device at address %@ has been orphaned (has no services)", description.address);
            
            [_allDevices removeObjectForKey:description.address];

            [self handleDeviceLoss:device];
        } else
        {
            [self handleDeviceUpdate:device];
        }
    }
}

- (void)discoveryProvider:(DiscoveryProvider *)provider didFailWithError:(NSError *)error
{
    NSLog(@"DiscoveryManager::discoveryProvider::didFailWithError %@", error.localizedDescription);
}

#pragma mark - Device Store

- (ServiceConfig *)lookupMatchServiceConfigFromDeviceStore:(NSString *)UUID
{
    __block ServiceConfig *serviceConfig;

    [[self.deviceStore storedDevices] enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger deviceIdx, BOOL *deviceStop)
    {
        [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
        {
            if ([service.serviceConfig.UUID isEqualToString:UUID])
            {
                serviceConfig = service.serviceConfig;

                *serviceStop = YES;
                *deviceStop = YES;
            }
        }];
    }];

    return serviceConfig;
}

- (ConnectableDevice *)lookupMatchDeviceFromDeviceStore:(ServiceConfig *)serviceConfig
{
    __block ConnectableDevice *foundDevice;

    [[self.deviceStore storedDevices] enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger deviceIdx, BOOL *deviceStop)
    {
        [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
        {
            if ([service.serviceConfig.UUID isEqualToString:serviceConfig.UUID])
            {
                foundDevice = device;

                *serviceStop = YES;
                *deviceStop = YES;
            }
        }];
    }];

    return foundDevice;
}

#pragma mark - Handle background state

- (void) hAppDidEnterBackground
{
    [self stopSSIDTimer];

    if (_searching)
    {
        _shouldResumeSearch = YES;
        [self stopDiscovery];
    }
}

- (void) hAppDidBecomeActive
{
    [self startSSIDTimer];

    if (_shouldResumeSearch)
    {
        _shouldResumeSearch = NO;
        [self startDiscovery];
    }
}

#pragma mark - Device Picker creation

- (DevicePicker *) devicePicker
{
    if (_currentPicker == nil)
    {
        _currentPicker = [[DevicePicker alloc] init];
        
        [self.compatibleDevices enumerateKeysAndObjectsUsingBlock:^(NSString *address, ConnectableDevice *device, BOOL *stop)
        {
            [_currentPicker discoveryManager:self didFindDevice:device];
        }];
    }
    
    return _currentPicker;
}

#pragma mark - ServiceConfigDelegate

- (void)serviceConfigUpdate:(ServiceConfig *)serviceConfig
{
    if (_useDeviceStore && self.deviceStore)
    {
        ConnectableDevice *device = [self lookupMatchDeviceFromDeviceStore:serviceConfig];

        if (device)
            [self.deviceStore updateDevice:device];
    }
}

@end
