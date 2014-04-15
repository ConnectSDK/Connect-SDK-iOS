//
//  DefaultConnectableDeviceStore.m
//  Connect SDK
//
//  Created by Jeremy White on 3/21/14.
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

#import "DefaultConnectableDeviceStore.h"


@implementation DefaultConnectableDeviceStore
{
    NSMutableArray *_storedDevices;
    NSString *_deviceStoreFilename;
    NSFileManager *_fileManager;

    NSDictionary *_deviceStore;

    BOOL _waitToWrite;

    dispatch_queue_t _deviceStoreQueue;
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _maxStoreDuration = 3 * 24 * 60 * 60; // 3 days
        _deviceStoreQueue = dispatch_queue_create("Connect_SDK_Device_Store", DISPATCH_QUEUE_SERIAL);

        _storedDevices = [NSMutableArray new];

        NSArray *base = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documents = [base lastObject];

        _deviceStoreFilename = [documents stringByAppendingPathComponent:@"Connect_SDK_Device_Store.json"];

        _fileManager = [NSFileManager defaultManager];

        [self load];
    }

    return self;
}

- (void) load
{
    if (![_fileManager fileExistsAtPath:_deviceStoreFilename])
    {
        _version = 1;
        _created = [[NSDate date] timeIntervalSince1970];
        _updated = [[NSDate date] timeIntervalSince1970];

        [_fileManager createFileAtPath:_deviceStoreFilename contents:nil attributes:nil];
    } else
    {
        NSError *error;
        NSString *deviceStoreJSON = [NSString stringWithContentsOfFile:_deviceStoreFilename encoding:NSUTF8StringEncoding error:&error];

        if (error)
        {
            NSLog(@"DefaultConnectableDeviceStore::load experienced error loading file: %@", error.localizedDescription);
            return;
        }

        NSData *deviceStoreData = [deviceStoreJSON dataUsingEncoding:NSUTF8StringEncoding];
        _deviceStore = [NSJSONSerialization JSONObjectWithData:deviceStoreData options:0 error:&error];

        if (error)
        {
            NSLog(@"DefaultConnectableDeviceStore::load experienced error parsing file: %@", error.localizedDescription);
            return;
        }

        NSArray *devicesFromStore = [_deviceStore objectForKey:@"devices"];

        if (!devicesFromStore || [devicesFromStore isKindOfClass:[NSNull class]])
            return;

        [devicesFromStore enumerateObjectsUsingBlock:^(NSDictionary *deviceDictionary, NSUInteger idx, BOOL *deviceStop)
        {
            ConnectableDevice *device = [[ConnectableDevice alloc] init];
            device.lastKnownIPAddress = deviceDictionary[@"lastKnownIPAddress"];
            device.lastSeenOnWifi = deviceDictionary[@"lastSeenOnWifi"];

            id lastConnected = deviceDictionary[@"lastConnected"];
            if (lastConnected && ![lastConnected isKindOfClass:[NSNull class]])
                device.lastConnected = [lastConnected doubleValue];

            id lastDetection = deviceDictionary[@"lastDetection"];
            if (lastDetection && ![lastDetection isKindOfClass:[NSNull class]])
                device.lastDetection = [lastDetection doubleValue];

            NSDictionary *services = deviceDictionary[@"services"];

            if (!services || [services isKindOfClass:[NSNull class]])
                return;

            [services enumerateKeysAndObjectsUsingBlock:^(NSString *UUID, NSDictionary *serviceDictionary, BOOL *serviceStop)
            {
                DeviceService *service = [[DeviceService alloc] initWithJSONObject:serviceDictionary];
                [device addService:service];
            }];

            [_storedDevices addObject:device];
        }];

        id version = _deviceStore[@"version"];
        if (version && ![version isKindOfClass:[NSNull class]])
            _version = [version intValue];

        id created = _deviceStore[@"created"];
        if (created && ![created isKindOfClass:[NSNull class]])
            _created = [created intValue];

        id updated = _deviceStore[@"updated"];
        if (updated && ![updated isKindOfClass:[NSNull class]])
            _updated = [updated intValue];
    }
}

- (void) setMaxStoreDuration:(double)maxStoreDuration
{
    _maxStoreDuration = maxStoreDuration;

    [self deleteOldUnusedDevices];
}

- (void) store
{
    if (_storedDevices && _deviceStoreFilename)
    {
        self.maxStoreDuration = _maxStoreDuration; // clean out old devices

        _updated = [[NSDate date] timeIntervalSince1970];

        NSMutableDictionary *newDeviceStore = [NSMutableDictionary new];
        newDeviceStore[@"version"] = @(self.version);
        newDeviceStore[@"created"] = @(self.created);
        newDeviceStore[@"updated"] = @(self.updated);

        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastDetection" ascending:NO];
        NSArray *sortedDevices = [_storedDevices sortedArrayUsingDescriptors:@[sortDescriptor]];
        NSMutableArray *devicesToStore = [NSMutableArray new];

        [sortedDevices enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger deviceIdx, BOOL *deviceStop)
        {
            NSDictionary *deviceDictionary = [self jsonRepresentationForDevice:device];

            if (deviceDictionary)
                [devicesToStore addObject:deviceDictionary];
        }];

        newDeviceStore[@"devices"] = [NSArray arrayWithArray:devicesToStore];

        _updated = [[NSDate date] timeIntervalSince1970];

        _deviceStore = [NSDictionary dictionaryWithDictionary:newDeviceStore];

        if (!_waitToWrite)
            [self writeStoreToDisk];
    }
}

- (void) addDevice:(ConnectableDevice *)device
{
    if (!device || device.services.count == 0)
        return;

    ConnectableDevice *storedDevice = [self storedDeviceForDevice:device];

    if (!storedDevice)
    {
        storedDevice = [[ConnectableDevice alloc] init];
        [_storedDevices addObject:storedDevice];
    }

    storedDevice.lastKnownIPAddress = device.lastKnownIPAddress;
    storedDevice.lastSeenOnWifi = device.lastSeenOnWifi;
    storedDevice.lastConnected = device.lastConnected;
    storedDevice.lastDetection = device.lastDetection;

    [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
    {
        [storedDevice removeServiceWithId:service.serviceDescription.serviceId];
        [storedDevice addService:service];
    }];

    [self store];
}

- (void) removeDevice:(ConnectableDevice *)device
{
    if (!device || device.services.count == 0)
        return;

    ConnectableDevice *storedDevice = [self storedDeviceForDevice:device];

    if (!storedDevice)
        return;

    [_storedDevices removeObject:storedDevice];

    [self store];
}

- (void) removeAll
{
    _storedDevices = [NSMutableArray new];

    [self store];
}

- (void) updateDevice:(ConnectableDevice *)device
{
    if (!device || device.services.count == 0)
        return;

    ConnectableDevice *storedDevice = [self storedDeviceForDevice:device];

    if (!storedDevice)
    {
        [self addDevice:device];
        return;
    }

    storedDevice.lastKnownIPAddress = device.lastKnownIPAddress;
    storedDevice.lastSeenOnWifi = device.lastSeenOnWifi;
    storedDevice.lastConnected = device.lastConnected;
    storedDevice.lastDetection = device.lastDetection;

    [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
    {
        DeviceService *storedService = [storedDevice serviceWithName:service.serviceDescription.serviceId];

        if (storedService)
        {
            storedService.serviceConfig = service.serviceConfig;
            storedService.serviceDescription = service.serviceDescription;
        } else
        {
            [storedDevice addService:service];
        }
    }];

    [self store];
}

- (NSArray *) storedDevices
{
    if (_storedDevices)
        return [NSArray arrayWithArray:_storedDevices];
    else
        return [NSArray new];
}

#pragma mark - Helper methods

- (ConnectableDevice *) storedDeviceForDevice:(ConnectableDevice *)device
{
    __block ConnectableDevice *foundDevice;

    [_storedDevices enumerateObjectsUsingBlock:^(ConnectableDevice *storedDevice, NSUInteger deviceIdx, BOOL *deviceStop)
    {
        [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
        {
            [storedDevice.services enumerateObjectsUsingBlock:^(DeviceService *storedService, NSUInteger storedServiceIdx, BOOL *storedServiceStop)
            {
                if ([service.serviceConfig.UUID isEqualToString:storedService.serviceConfig.UUID])
                {
                    foundDevice = storedDevice;

                    *storedServiceStop = YES;
                    *serviceStop = YES;
                    *deviceStop = YES;
                }
            }];
        }];
    }];

    return foundDevice;
}

- (void) writeStoreToDisk
{
    double lastUpdated = self.updated;
    _waitToWrite = YES;

    dispatch_async(_deviceStoreQueue, ^
    {
        NSDictionary *deviceStore = [_deviceStore copy];

        NSError *jsonError;
        NSData *deviceStoreJSONData = [NSJSONSerialization dataWithJSONObject:deviceStore options:NSJSONWritingPrettyPrinted error:&jsonError];
        NSString *deviceStoreJSON = [[NSString alloc] initWithData:deviceStoreJSONData encoding:NSUTF8StringEncoding];

        if (jsonError)
        {
            NSLog(@"DefaultConnectableDeviceStore::writeStoreToDisk failed to parse with error: %@", jsonError.localizedDescription);
            _waitToWrite = NO;
            return;
        }

        NSError *writeError;
        [deviceStoreJSON writeToFile:_deviceStoreFilename atomically:YES encoding:NSUTF8StringEncoding error:&writeError];

        if (writeError)
        {
            NSLog(@"DefaultConnectableDeviceStore::writeStoreToDisk failed to write with error: %@", writeError.localizedDescription);
            _waitToWrite = NO;
            return;
        }

        _waitToWrite = NO;

        if (lastUpdated != _updated)
            [self writeStoreToDisk];
    });
}

- (NSDictionary *) jsonRepresentationForDevice:(ConnectableDevice *)device
{
    if (device.services.count == 0)
        return nil;

    NSMutableDictionary *deviceDictionary = [NSMutableDictionary new];
    deviceDictionary[@"friendlyName"] = device.friendlyName;
    deviceDictionary[@"lastKnownIPAddress"] = device.lastKnownIPAddress;
    deviceDictionary[@"lastSeenOnWifi"] = device.lastSeenOnWifi;
    deviceDictionary[@"lastConnected"] = @(device.lastConnected);
    deviceDictionary[@"lastDetection"] = @(device.lastDetection);

    NSMutableDictionary *servicesDictionary = [NSMutableDictionary new];

    [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
    {
        NSDictionary *serviceDictionary = [service toJSONObject];
        [servicesDictionary setObject:serviceDictionary forKey:service.serviceDescription.UUID];
    }];

    deviceDictionary[@"services"] = [NSDictionary dictionaryWithDictionary:servicesDictionary];

    return [NSDictionary dictionaryWithDictionary:deviceDictionary];
}

- (void) deleteOldUnusedDevices
{
    __block NSMutableArray *devicesToRemove = [NSMutableArray new];

    [_storedDevices enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop)
    {
        if (device.lastConnected > 0)
            return;

        double currentTime = [[NSDate date] timeIntervalSince1970];
        double storeDuration = currentTime - device.lastDetection;

        if (storeDuration > _maxStoreDuration)
            [devicesToRemove addObject:device];
    }];

    [devicesToRemove enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop)
    {
        [self removeDevice:device];
    }];
}

@end
