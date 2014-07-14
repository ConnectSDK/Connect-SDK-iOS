//
//  CastDiscoveryProvider.m
//  Connect SDK
//
//  Created by Jeremy White on 2/7/14.
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

#import "CastDiscoveryProvider.h"
#import <GoogleCast/GoogleCast.h>
#import "ServiceDescription.h"
#import "CastService.h"

@interface CastDiscoveryProvider () <GCKDeviceScannerListener>
{
    GCKDeviceScanner *_deviceScanner;
    NSMutableDictionary *_devices;
    NSMutableDictionary *_deviceDescriptions;
}

@end

@implementation CastDiscoveryProvider

- (instancetype) init
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

    if (!_deviceScanner.scanning)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_deviceScanner startScan];
        });
    }
}

- (void)stopDiscovery
{
    self.isRunning = NO;

    if (_deviceScanner.scanning)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_deviceScanner stopScan];
        });
    }
    
    _devices = [NSMutableDictionary new];
    _deviceDescriptions = [NSMutableDictionary new];
}

- (BOOL) isEmpty
{
    // Since we are only searching for one type of device & parameters are unnecessary
    return NO;
}

#pragma mark - GCKDeviceScannerListenerDelegate

- (void)deviceDidComeOnline:(GCKDevice *)device
{
    DLog(@"%@", device.friendlyName);

    if ([_devices objectForKey:device.deviceID])
        return;
    
    ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:device.ipAddress UUID:device.deviceID];
    serviceDescription.serviceId = kConnectSDKCastServiceId;
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
    DLog(@"%@", device.friendlyName);

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
