//
//  CastDiscoveryProvider.m
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "CastDiscoveryProvider.h"
#import <GoogleCast/GoogleCast.h>
#import "ServiceDescription.h"

@interface CastDiscoveryProvider () <GCKDeviceScannerListener>
{
    GCKDeviceScanner *_deviceScanner;
    NSMutableDictionary *_devices;
    NSMutableDictionary *_deviceDescriptions;
}

@end

@implementation CastDiscoveryProvider

- (id) init
{
    self = [super init];
    
    if (self)
    {
        _devices = [NSMutableDictionary new];
        _deviceDescriptions = [NSMutableDictionary new];
        
        _deviceScanner = [GCKDeviceScanner new];
        [_deviceScanner addListener:self];
    }
    
    return self;
}

- (void)startDiscovery
{
    self.isRunning = YES;
    [_deviceScanner startScan];
}

- (void)stopDiscovery
{
    self.isRunning = NO;
    [_deviceScanner stopScan];
}

- (BOOL) isEmpty
{
    return _devices.count == 0;
}

#pragma mark - GCKDeviceScannerListenerDelegate

- (void)deviceDidComeOnline:(GCKDevice *)device
{
    NSLog(@"CastDiscoveryProvider::deviceDidComeOnline:%@", device.friendlyName);

    if ([_devices objectForKey:device.deviceID])
        return;
    
    ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:device.ipAddress UUID:device.deviceID];
    serviceDescription.serviceId = @"Chromecast";
    serviceDescription.friendlyName = device.friendlyName;
    serviceDescription.port = device.servicePort;
    serviceDescription.manufacturer = device.manufacturer;
    serviceDescription.modelName = device.modelName;
    
    [_devices setObject:device forKey:device.deviceID];
    [_deviceDescriptions setObject:serviceDescription forKey:device.deviceID];

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate discoveryProvider:self didFindService:serviceDescription];
    });
}

- (void)deviceDidGoOffline:(GCKDevice *)device
{
    NSLog(@"CastDiscoveryProvider::deviceDidGoOffline:%@", device.friendlyName);

    if (![_devices objectForKey:device.deviceID])
        return;
    
    ServiceDescription *serviceDescription = [_deviceDescriptions objectForKey:device.deviceID];

    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate discoveryProvider:self didLoseService:serviceDescription];
    });
    
    [_devices removeObjectForKey:device.deviceID];
    [_deviceDescriptions removeObjectForKey:device.deviceID];
}

@end
