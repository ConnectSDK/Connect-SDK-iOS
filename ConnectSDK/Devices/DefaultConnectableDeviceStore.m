//
// Created by Jeremy White on 3/21/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DefaultConnectableDeviceStore.h"
#import "ConnectableDevice.h"


@implementation DefaultConnectableDeviceStore
{
    NSMutableDictionary *_storedDevices;
    NSString *_autoSaveFilename;
    NSFileManager *_fileManager;
}

- (id) init
{
    self = [super init];

    if (self)
    {
        _storedDevices = [NSMutableDictionary new];

        NSArray *base = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documents = [base lastObject];

        _autoSaveFilename = [documents stringByAppendingPathComponent:@"defaultDeviceStore.archive"];

        _fileManager = [NSFileManager defaultManager];

        [self load];
    }

    return self;
}

- (void) load
{
    if (![_fileManager fileExistsAtPath:_autoSaveFilename])
    {
        [_fileManager createFileAtPath:_autoSaveFilename contents:nil attributes:nil];
    } else
    {
        NSArray *devicesFromStore = [NSKeyedUnarchiver unarchiveObjectWithFile:_autoSaveFilename];

        [devicesFromStore enumerateObjectsUsingBlock:^(ConnectableDevice *device, NSUInteger idx, BOOL *stop)
        {
            [_storedDevices setObject:device forKey:device.address];
        }];
    }
}

- (void) store
{
    if (_storedDevices && _autoSaveFilename)
    {
        NSArray *devicesToStore = [_storedDevices allValues];

        [NSKeyedArchiver archiveRootObject:devicesToStore toFile:_autoSaveFilename];
    }
}

- (void) addDevice:(ConnectableDevice *)device
{
    if (device && device.address)
        [_storedDevices setObject:device forKey:device.address];

    [self store];
}

- (void) removeDevice:(ConnectableDevice *)device
{
    if (device && device.address)
        [_storedDevices removeObjectForKey:device.address];

    [self store];
}

- (void) removeAll
{
    _storedDevices = [NSMutableDictionary new];

    [self store];
}

- (void) updateDevice:(ConnectableDevice *)device
{
    [self addDevice:device];

    [self store];
}

- (NSArray *) storedDevices
{
    if (_storedDevices)
        return [_storedDevices allValues];
    else
        return [NSArray new];
}

@end
