//
// Created by Jeremy White on 3/21/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectableDevice.h"

@protocol ConnectableDeviceStore <NSObject>

- (void) addDevice:(ConnectableDevice *)device;
- (void) removeDevice:(ConnectableDevice *)device;
- (void) updateDevice:(ConnectableDevice *)device;

- (NSArray *) storedDevices;
- (void) removeAll;

@end
