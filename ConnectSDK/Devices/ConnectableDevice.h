//
//  ConnectableDevice.h
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceDescription.h"
#import "DeviceService.h"
#import "ConnectableDeviceDelegate.h"
#import "DeviceServiceDelegate.h"

#import "Launcher.h"
#import "VolumeControl.h"
#import "TVControl.h"
#import "MediaControl.h"
#import "ExternalInputControl.h"
#import "ToastControl.h"
#import "TextInputControl.h"
#import "MediaPlayer.h"
#import "WebAppLauncher.h"
#import "KeyControl.h"
#import "MouseControl.h"
#import "PowerControl.h"

typedef enum {
    ConnectableDevicePairingLevelOff = 0,
    ConnectableDevicePairingLevelOn
} ConnectableDevicePairingLevel;

@interface ConnectableDevice : NSObject <NSCoding, DeviceServiceDelegate>

+ (instancetype) connectableDeviceWithDescription:(ServiceDescription *)description;

@property (nonatomic, strong, readonly) ServiceDescription *serviceDescription;
@property (nonatomic, weak) id<ConnectableDeviceDelegate> delegate;

#pragma mark - General info

- (NSString *) address;
- (NSString *) friendlyName;
- (NSString *) modelName;
- (NSString *) modelNumber;
- (NSString *) connectedServiceNames;

- (void) connect;
- (void) disconnect;
- (BOOL) isConnectable;

#pragma mark - Service management

- (NSArray *) services;
- (BOOL) hasServices;
- (void) addService:(DeviceService *)service;
- (void) removeServiceWithId:(NSString *)serviceId;
- (DeviceService *)serviceWithName:(NSString *)serviceName;

#pragma mark - Capabilities

#pragma mark Helpers

- (NSArray *) capabilities;
- (BOOL) hasCapability:(NSString *)capability;
- (BOOL) hasCapabilities:(NSArray *)capabilities;
- (BOOL) hasAnyCapability:(NSArray *)capabilities;

#pragma mark Objects

- (id<Launcher>) launcher;
- (id<ExternalInputControl>) externalInputControl;
- (id<MediaPlayer>) mediaPlayer;
- (id<MediaControl>) mediaControl;
- (id<VolumeControl>)volumeControl;
- (id<TVControl>)tvControl;
- (id<KeyControl>) keyControl;
- (id<TextInputControl>) textInputControl;
- (id<MouseControl>)mouseControl;
- (id<PowerControl>)powerControl;
- (id<ToastControl>) toastControl;
- (id<WebAppLauncher>) webAppLauncher;

@end
