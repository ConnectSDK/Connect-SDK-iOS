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
    NSMutableDictionary *_activeDevices; // active ConnectableDevice objects
    NSMutableDictionary *_storedDevices; // inactive NSDictionary objects containing ConnectableDevice information
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

        _activeDevices = [NSMutableDictionary new];
        _storedDevices = [NSMutableDictionary new];

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
            DLog(@"Experienced error loading file: %@", error.localizedDescription);
            return;
        }

        NSData *deviceStoreData = [deviceStoreJSON dataUsingEncoding:NSUTF8StringEncoding];
        
        @synchronized (self)
        {
            _deviceStore = [NSJSONSerialization JSONObjectWithData:deviceStoreData options:0 error:&error];
        }

        if (error)
        {
            DLog(@"Experienced error parsing file: %@", error.localizedDescription);
            return;
        }

        NSDictionary *devicesFromStore = [_deviceStore objectForKey:@"devices"];

        if (!devicesFromStore || [devicesFromStore isKindOfClass:[NSNull class]])
            _storedDevices = [NSMutableDictionary new];
        else
            _storedDevices = [NSMutableDictionary dictionaryWithDictionary:devicesFromStore];

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
        newDeviceStore[@"devices"] = [NSDictionary dictionaryWithDictionary:_storedDevices];

        _updated = [[NSDate date] timeIntervalSince1970];
        
        @synchronized(self)
        {
            _deviceStore = [NSDictionary dictionaryWithDictionary:newDeviceStore];
        }

        if (!_waitToWrite)
            [self writeStoreToDisk];
    }
}

- (void) addDevice:(ConnectableDevice *)device
{
    if (!device || device.services.count == 0)
        return;

    if (![_activeDevices objectForKey:device.id])
        [_activeDevices setObject:device forKey:device.id];

    NSDictionary *storedDevice = [_storedDevices objectForKey:device.id];

    if (storedDevice)
    {
        [self updateDevice:device];
    } else
    {
        storedDevice = [self jsonRepresentationForDevice:device];

        if (storedDevice)
        {
            [_storedDevices setObject:storedDevice forKey:device.id];

            [self store];
        }
    }
}

- (void) removeDevice:(ConnectableDevice *)device
{
    if (!device || device.services.count == 0)
        return;

    [_storedDevices removeObjectForKey:device.id];

    [self store];
}

- (void) removeAll
{
    _storedDevices = [NSMutableDictionary new];

    [self store];
}

- (void) updateDevice:(ConnectableDevice *)device
{
    if (!device || device.services.count == 0)
        return;

    NSDictionary *storedDeviceInfo = [self storedDeviceForUUID:device.id];

    if (!storedDeviceInfo || [storedDeviceInfo isKindOfClass:[NSNull class]])
        return;

    NSMutableDictionary *storedDevice = [NSMutableDictionary dictionaryWithDictionary:storedDeviceInfo];

    // since this is an update, we will serialize ConnectableDevice into JSON manually. This way we avoid
    // removing reference to any services that weren't discovered for whatever reason during this session

    storedDevice[@"lastKnownIPAddress"] = device.lastKnownIPAddress;
    storedDevice[@"lastSeenOnWifi"] = device.lastSeenOnWifi;
    storedDevice[@"lastConnected"] = @(device.lastConnected);
    storedDevice[@"lastDetection"] = @(device.lastDetection);

    NSDictionary *servicesInfo = storedDevice[@"services"];

    if (!servicesInfo || [servicesInfo isKindOfClass:[NSNull class]])
        servicesInfo = [NSDictionary new];

    NSMutableDictionary *services = [NSMutableDictionary dictionaryWithDictionary:servicesInfo];

    [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *serviceInfo = [service toJSONObject];

        if (serviceInfo)
            [services setObject:serviceInfo forKey:service.serviceDescription.UUID];
    }];

    storedDevice[@"services"] = [NSDictionary dictionaryWithDictionary:services];

    NSDictionary *deviceToStore = [NSDictionary dictionaryWithDictionary:storedDevice];
    [_storedDevices setObject:deviceToStore forKey:device.id];
    [_activeDevices setObject:device forKey:device.id];

    [self store];
}

- (NSDictionary *) storedDevices
{
    if (_storedDevices)
        return [NSDictionary dictionaryWithDictionary:_storedDevices];
    else
        return [NSDictionary new];
}

- (ConnectableDevice *) deviceForId:(NSString *)id
{
    if (!id || id.length == 0 || [id isKindOfClass:[NSNull class]])
        return nil;

    ConnectableDevice *foundDevice = [self activeDeviceForUUID:id];

    if (!foundDevice)
    {
        NSDictionary *foundDeviceInfo = [self storedDeviceForUUID:id];

        if (foundDeviceInfo)
            foundDevice = [[ConnectableDevice alloc] initWithJSONObject:foundDeviceInfo];
    }

    if (foundDevice && ![_activeDevices objectForKey:foundDevice.id])
        [_activeDevices setObject:foundDevice forKey:foundDevice.id];

    return foundDevice;
}

- (ServiceConfig *) serviceConfigForUUID:(NSString *)UUID
{
    if (!UUID || UUID.length == 0 || [UUID isKindOfClass:[NSNull class]])
        return nil;

    ServiceConfig *foundConfig = nil;

    NSDictionary *device = [self storedDeviceForUUID:UUID];

    if (device && ![device isKindOfClass:[NSNull class]])
    {
        NSDictionary *services = [device objectForKey:@"services"];

        if (services && ![services isKindOfClass:[NSNull class]])
        {
            NSDictionary *service = [services objectForKey:UUID];

            if (service && ![service isKindOfClass:[NSNull class]])
            {
                NSDictionary *serviceConfigInfo = [service objectForKey:@"config"];

                if (serviceConfigInfo && ![serviceConfigInfo isKindOfClass:[NSNull class]])
                {
                    foundConfig = [ServiceConfig serviceConfigWithJSONObject:serviceConfigInfo];
                }
            }
        }
    }

    return foundConfig;
}

#pragma mark - Helper methods

- (ConnectableDevice *) activeDeviceForUUID:(NSString *)UUID
{
    __block ConnectableDevice *foundDevice = nil;

    // Check active devices
    foundDevice = [_activeDevices objectForKey:UUID];

    // Check active device services
    if (!foundDevice)
    {
        [_activeDevices enumerateKeysAndObjectsUsingBlock:^(id key, ConnectableDevice *device, BOOL *deviceStop)
        {
            [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger idx, BOOL *serviceStop)
            {
                if ([UUID isEqualToString:service.serviceDescription.UUID])
                {
                    foundDevice = device;

                    *deviceStop = YES;
                    *serviceStop = YES;
                }
            }];
        }];
    }

    return foundDevice;
}

- (NSDictionary *) storedDeviceForUUID:(NSString *)UUID
{
    __block NSDictionary *foundDevice = nil;

    // Check stored devices
    foundDevice = [_storedDevices objectForKey:UUID];

    // Check stored device services
    if (!foundDevice)
    {
        [_storedDevices enumerateKeysAndObjectsUsingBlock:^(NSString *deviceUUID, NSDictionary *device, BOOL *stop)
        {
            NSDictionary *services = device[@"services"];

            if (services && [services objectForKey:UUID])
            {
                foundDevice = device;
                *stop = YES;
            }
        }];
    }

    return foundDevice;
}

- (void) writeStoreToDisk
{
    double lastUpdated = self.updated;
    _waitToWrite = YES;

    dispatch_async(_deviceStoreQueue, ^
    {
        NSError *jsonError;
        NSData *deviceStoreJSONData;
        
        @synchronized (self)
        {
            deviceStoreJSONData = [NSJSONSerialization dataWithJSONObject:_deviceStore options:NSJSONWritingPrettyPrinted error:&jsonError];
        }
        
        NSString *deviceStoreJSON = [[NSString alloc] initWithData:deviceStoreJSONData encoding:NSUTF8StringEncoding];
        
        if (jsonError)
        {
            DLog(@"Failed to parse with error: %@", jsonError.localizedDescription);
            _waitToWrite = NO;
            return;
        }

        NSError *writeError;
        [deviceStoreJSON writeToFile:_deviceStoreFilename atomically:YES encoding:NSUTF8StringEncoding error:&writeError];

        if (writeError)
        {
            DLog(@"Failed to write with error: %@", writeError.localizedDescription);
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
    if (!device || device.services.count == 0)
        return nil;

    NSMutableDictionary *deviceDictionary = [NSMutableDictionary new];
    deviceDictionary[@"id"] = device.id;
    deviceDictionary[@"friendlyName"] = device.friendlyName;
    deviceDictionary[@"lastKnownIPAddress"] = device.lastKnownIPAddress;
    deviceDictionary[@"lastSeenOnWifi"] = device.lastSeenOnWifi;
    deviceDictionary[@"lastConnected"] = @(device.lastConnected);
    deviceDictionary[@"lastDetection"] = @(device.lastDetection);

    NSMutableDictionary *servicesDictionary = [NSMutableDictionary new];

    [device.services enumerateObjectsUsingBlock:^(DeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
    {
        NSDictionary *serviceDictionary = [service toJSONObject];

        if (serviceDictionary)
            [servicesDictionary setObject:serviceDictionary forKey:service.serviceDescription.UUID];
    }];

    deviceDictionary[@"services"] = [NSDictionary dictionaryWithDictionary:servicesDictionary];

    return [NSDictionary dictionaryWithDictionary:deviceDictionary];
}

- (void) deleteOldUnusedDevices
{
    __block NSMutableArray *devicesToRemove = [NSMutableArray new];

    [_storedDevices enumerateKeysAndObjectsUsingBlock:^(NSString *UUID, NSDictionary *deviceInfo, BOOL *stop)
    {
        double lastConnected = 0;
        double lastDetection = 0;

        id lastConnectedObject = deviceInfo[@"lastConnected"];
        if (lastConnectedObject && ![lastConnectedObject isKindOfClass:[NSNull class]])
            lastConnected = [lastConnectedObject doubleValue];

        id lastDetectionObject = deviceInfo[@"lastDetection"];
        if (lastDetectionObject && ![lastDetectionObject isKindOfClass:[NSNull class]])
            lastDetection = [lastDetectionObject doubleValue];

        if (lastConnected > 0)
            return;

        double currentTime = [[NSDate date] timeIntervalSince1970];
        double storeDuration = currentTime - lastDetection;

        if (storeDuration > _maxStoreDuration)
            [devicesToRemove addObject:UUID];
    }];

    if (devicesToRemove)
    {
        [devicesToRemove enumerateObjectsUsingBlock:^(NSString *UUID, NSUInteger idx, BOOL *stop)
        {
            [_storedDevices removeObjectForKey:UUID];
        }];
    }
}

@end
