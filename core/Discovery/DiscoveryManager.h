//
//  DiscoveryManager.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#import <Foundation/Foundation.h>
#import "DiscoveryManagerDelegate.h"
#import "DevicePicker.h"
#import "ConnectableDeviceStore.h"

/*!
 * ###Overview
 *
 * At the heart of Connect SDK is DiscoveryManager, a multi-protocol service discovery engine with a pluggable architecture. Much of your initial experience with Connect SDK will be with the DiscoveryManager class, as it consolidates discovered service information into ConnectableDevice objects.
 *
 * ###In depth
 * DiscoveryManager supports discovering services of differing protocols by using DiscoveryProviders. Many services are discoverable over [SSDP][0] and are registered to be discovered with the SSDPDiscoveryProvider class.
 *
 * As services are discovered on the network, the DiscoveryProviders will notify DiscoveryManager. DiscoveryManager is capable of attributing multiple services, if applicable, to a single ConnectableDevice instance. Thus, it is possible to have a mixed-mode ConnectableDevice object that is theoretically capable of more functionality than a single service can provide.
 *
 * DiscoveryManager keeps a running list of all discovered devices and maintains a filtered list of devices that have satisfied any of your CapabilityFilters. This filtered list is used by the DevicePicker when presenting the user with a list of devices.
 *
 * Only one instance of the DiscoveryManager should be in memory at a time. To assist with this, DiscoveryManager has singleton accessors at sharedManager and sharedManagerWithDeviceStore:.
 *
 * Example:
 *
 * @capability kMediaControlPlay
 *
 @code
   DiscoveryManager *discoveryManager = [DiscoveryManager sharedManager];
   discoveryManager.delegate = self; // set delegate to listen for discovery events
   [discoveryManager startDiscovery];
 @endcode
 *
 * [0]: http://tools.ietf.org/html/draft-cai-ssdp-v1-03
 */
@interface DiscoveryManager : NSObject <ConnectableDeviceDelegate>

/*!
 * Delegate which should receive discovery updates. It is not necessary to set this delegate property unless you are implementing your own device picker. Connect SDK provides a default DevicePicker which acts as a DiscoveryManagerDelegate, and should work for most cases.
 *
 * If you have provided a capabilityFilters array, the delegate will only receive update messages for ConnectableDevices which satisfy at least one of the CapabilityFilters. If no capabilityFilters array is provided, the delegate will receive update messages for all ConnectableDevice objects that are discovered.
 */
@property (nonatomic, weak) id<DiscoveryManagerDelegate> delegate;

/*!
 * Singleton accessor for DiscoveryManager. This method calls sharedManagerWithDeviceStore: and passes an instance of DefaultConnectableDeviceStore.
 */
+ (instancetype) sharedManager;

/*!
 * Singleton accessor for DiscoveryManager, will initialize singleton with reference to a custom ConnectableDeviceStore object.
 *
 * @param deviceStore (optional) An object which implements the ConnectableDeviceStore protocol to be used for save/load of device information. You may provide nil to completely disable the device store capabilities of the SDK.
 */
+ (instancetype) sharedManagerWithDeviceStore:(id<ConnectableDeviceStore>)deviceStore;

/*!
 * Filtered list of discovered ConnectableDevices, limited to devices that match at least one of the CapabilityFilters in the capabilityFilters array. Each ConnectableDevice object is keyed against its current IP address.
 */
- (NSDictionary *) compatibleDevices;

/*!
 * List of all devices discovered by DiscoveryManager. Each ConnectableDevice object is keyed against its current IP address.
 */
- (NSDictionary *) allDevices;

#pragma mark - Configuration & Device Registration

// @cond INTERNAL

/*
 * Registers a commonly-used set of DeviceServices with DiscoveryManager. This method will be called on first call of startDiscovery if no DeviceServices have been registered.
 *
 * - CastDiscoveryProvider
 *   + CastService
 * - SSDPDiscoveryProvider
 *   + DIALService
 *   + DLNAService (limited to LG TVs, currently)
 *   + NetcastTVService
 *   + RokuService
 *   + WebOSTVService
 */
- (void) registerDefaultServices;

/*
 * Registers a DeviceService with DiscoveryManager and tells it which DiscoveryProvider to use to find it. Each DeviceService has an NSDictionary of discovery parameters that its DiscoveryProvider will use to find it.
 *
 * @param deviceClass Class for object that should be instantiated when DeviceService is found
 * @param discoveryClass Class for object that should discover this DeviceService. If a DiscoveryProvider of this class already exists, then the existing DiscoveryProvider will be used.
 */
- (void) registerDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass;

/*
 * Unregisters a DeviceService with DiscoveryManager. If no other DeviceServices are set to being discovered with the associated DiscoveryProvider, then that DiscoveryProvider instance will be stopped and shut down.
 *
 * @param deviceClass Class for DeviceService that should no longer be discovered
 * @param discoveryClass Class for DiscoveryProvider that is discovering DeviceServices of deviceClass type
 */
- (void) unregisterDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass;

// @endcond

/*!
 * A ConnectableDevice will be displayed in the DevicePicker and compatibleDevices array if it matches any of the CapabilityFilter objects in this array.
 */
@property (nonatomic, strong) NSArray *capabilityFilters;

/*!
 * The pairingLevel property determines whether capabilities that require pairing (such as entering a PIN) will be available.
 *
 * If pairingLevel is set to DeviceServicePairingLevelOn, ConnectableDevices that require pairing will prompt the user to pair when connecting to the ConnectableDevice.
 *
 * If pairingLevel is set to DeviceServicePairingLevelOff (the default), connecting to the device will avoid requiring pairing if possible but some capabilities may not be available.
 */
@property (nonatomic) DeviceServicePairingLevel pairingLevel;

#pragma mark - Control

/*!
 * Start scanning for devices on the local network.
 */
- (void) startDiscovery;

/*!
 * Stop scanning for devices.
 *
 * This method will be called when your app enters a background state. When your app resumes, startDiscovery will be called.
 */
- (void) stopDiscovery;

#pragma mark - Device Picker

/*!
 * Get a DevicePicker to show compatible ConnectableDevices that have been found by DiscoveryManager.
 *
 * @return DevicePicker DevicePicker singleton for use in picking devices
 */
- (DevicePicker*) devicePicker;

#pragma mark - Device Store

/*!
 * ConnectableDeviceStore object which loads & stores references to all discovered devices. Pairing codes/keys, SSL certificates, recent access times, etc are kept in the device store.
 *
 * ConnectableDeviceStore is a protocol which may be implemented as needed. A default implementation, DefaultConnectableDeviceStore, exists for convenience and will be used if no other device store is provided.
 *
 * In order to satisfy user privacy concerns, you should provide a UI element in your app which exposes the ConnectableDeviceStore removeAll method.
 *
 * To disable the ConnectableDeviceStore capabilities of Connect SDK, set this value to nil. This may be done at the time of instantiation with `[DiscoveryManager sharedManagerWithDeviceStore:nil]`.
 */
@property (nonatomic, strong) id<ConnectableDeviceStore> deviceStore;

/*!
 * Whether pairing state will be automatically loaded/saved in the deviceStore. This property is not available for direct modification. To disable the device store,
 */
@property (nonatomic, readonly) BOOL useDeviceStore;

// @cond INTERNAL

@property (nonatomic, readonly) NSDictionary *deviceClasses;

@property (nonatomic, readonly) NSArray *discoveryProviders;

// @endcond

@end
