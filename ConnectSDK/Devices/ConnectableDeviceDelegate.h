//
//  ConnectableDeviceDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ConnectableDevice;
@class DeviceService;

@protocol ConnectableDeviceDelegate <NSObject>

- (void) connectableDeviceReady:(ConnectableDevice *)device;
- (void) connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error;

@optional

- (void) connectableDevice:(ConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed;
- (void) connectableDevice:(ConnectableDevice *)device connectionFailedWithError:(NSError *)error;

- (void) connectableDeviceConnectionRequired:(ConnectableDevice *)device forService:(DeviceService *)service;
- (void) connectableDeviceConnectionSuccess:(ConnectableDevice*)device forService:(DeviceService *)service;
- (void) connectableDevice:(ConnectableDevice*)device service:(DeviceService *)service disconnectedWithError:(NSError*)error;
- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service didFailConnectWithError:(NSError*)error;

- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingRequiredOfType:(int)pairingType withData:(id)pairingData;
- (void) connectableDevicePairingSuccess:(ConnectableDevice*)device service:(DeviceService *)service;
- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingFailedWithError:(NSError*)error;

@end
