//
// Created by Jeremy White on 6/16/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "MultiScreenDiscoveryProvider.h"
#import "ServiceDescription.h"
#import <SamsungMultiscreen/SamsungMultiscreen.h>
#import "MultiScreenService.h"


@interface MultiScreenDiscoveryProvider ()

@property (nonatomic) NSTimer *searchTimer;

@end

@implementation MultiScreenDiscoveryProvider
{
    NSMutableDictionary *_devices;
    BOOL _isEmpty;
}

- (id) init
{
    self = [super init];

    if (self)
    {
        _isEmpty = YES;

        [self setUpDiscoveryCallback];
    }

    return self;
}

- (void) setUpDiscoveryCallback
{
    __weak MultiScreenDiscoveryProvider *weakSelf = self;

    _findDevicesCallback = ^(NSArray *array) {
        MultiScreenDiscoveryProvider *strongSelf = weakSelf;

        if (strongSelf)
            [strongSelf updateDevices:array];
    };
}

- (void) updateDevices:(NSArray *)array
{
    NSMutableArray *newDevices = [NSMutableArray new];
    NSMutableArray *lostDevices = [NSMutableArray new];

    [array enumerateObjectsUsingBlock:^(MSDevice *device, NSUInteger idx, BOOL *stop) {
        if (self.devices[device.deviceId])
            return;

        [newDevices addObject:device];
    }];

    [self.devices enumerateKeysAndObjectsUsingBlock:^(NSString *preExistingDeviceId, MSDevice *preExistingDevice, BOOL *searchStop) {
        __block BOOL foundDevice = NO;

        [array enumerateObjectsUsingBlock:^(MSDevice *device, NSUInteger deviceIdx, BOOL *deviceStop) {
            if ([device.deviceId isEqualToString:preExistingDeviceId])
            {
                foundDevice = YES;
                *deviceStop = YES;
            }
        }];

        if (!foundDevice)
            [lostDevices addObject:preExistingDevice];
    }];

    for (MSDevice *device in newDevices)
        [self addDevice:device];

    for (MSDevice *device in lostDevices)
        [self removeDevice:device];
}

- (void) addDevice:(MSDevice *)device
{
    if (!device)
        return;

    if (self.devices[device.deviceId])
        return;

    _devices[device.deviceId] = device;

    if (self.delegate && [self.delegate respondsToSelector:@selector(discoveryProvider:didFindService:)])
    {
        ServiceDescription *description = [ServiceDescription descriptionWithAddress:device.ipAddress UUID:device.deviceId];
        description.serviceId = kConnectSDKMultiScreenTVServiceId;
        description.friendlyName = device.name;
        description.locationResponseHeaders = device.attributes;

        [self.delegate discoveryProvider:self didFindService:description];
    }
}

- (void) removeDevice:(MSDevice *)device
{
    if (!device)
        return;

    if (!self.devices[device.deviceId])
        return;

    [_devices removeObjectForKey:device.deviceId];

    if (self.delegate && [self.delegate respondsToSelector:@selector(discoveryProvider:didLoseService:)])
    {
        ServiceDescription *description = [ServiceDescription descriptionWithAddress:device.ipAddress UUID:device.deviceId];
        description.serviceId = kConnectSDKMultiScreenTVServiceId;
        description.friendlyName = device.name;
        description.locationResponseHeaders = device.attributes;

        [self.delegate discoveryProvider:self didLoseService:description];
    }
}

- (NSDictionary *) devices
{
    return [NSDictionary dictionaryWithDictionary:_devices];
}

- (void) startDiscovery
{
    if (self.isRunning)
        return;

    _devices = [NSMutableDictionary new];

    self.isRunning = YES;

    self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(search) userInfo:nil repeats:YES];
    [self.searchTimer fire];
}

- (void) stopDiscovery
{
    if (self.searchTimer)
    {
        [self.searchTimer invalidate];
        self.searchTimer = nil;
    }

    self.isRunning = NO;
}

- (void) search
{
    [MSDevice searchWithCompletionBlock:_findDevicesCallback queue:dispatch_get_main_queue()];
}

- (void) addDeviceFilter:(NSDictionary *)parameters
{
    // a full implementation of this method (see SSDPDiscoveryProvider) is not needed at this time, since only one filter will ever be added
    _isEmpty = NO;
}

- (void) removeDeviceFilter:(NSDictionary *)parameters
{
    // a full implementation of this method (see SSDPDiscoveryProvider) is not needed at this time, since only one filter will ever be added
    _isEmpty = YES;
}

- (BOOL) isEmpty
{
    return _isEmpty;
}

@end
