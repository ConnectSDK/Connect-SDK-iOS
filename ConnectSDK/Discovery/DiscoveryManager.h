//
//  DiscoveryManager.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscoveryManagerDelegate.h"
#import "DevicePicker.h"
#import "ConnectableDeviceStore.h"

/*!
 * DiscoveryManager is used to find devices on the local network.
 *
 * Example:
 *
 @code
   DiscoveryManager* discoveryManager = [DiscoveryManager sharedManager];
   discoveryManager.delegate = self; // set delegate to listen for discovery events
   [discoveryManager startDiscovery];
 @endcode
 *
 * To show a picker popup (when clicking on a share button):
 *
 @code
   DevicePicker* picker = [discoveryManager devicePicker];
   picker.delegate = self; // set delegate to listen for picker events
   [picker showPicker];
 @endcode
 */
@interface DiscoveryManager : NSObject

/*!
 * Delegate which should receive discovery updates. It is not necessary to set this
 * delegate property unless you are implementing your own device picker. Connect SDK
 * provides a default DevicePicker which acts as a DiscoveryManagerDelegate, and
 * should work for most cases.
 */
@property (nonatomic, weak) id<DiscoveryManagerDelegate> delegate;

/*!
 * Get an instance of DiscoveryManager.
 */
+ (instancetype) sharedManager;

/*!
 * Get an instance of DiscoveryManager with a custom ConnectableDeviceStore
 * to save pairing information.
 * @param deviceStore ConnectableDeviceStore to be used for save/load of
 *                    device information
 */
+ (instancetype) sharedManagerWithDeviceStore:(id<ConnectableDeviceStore>)deviceStore;

/**
 * Get filtered devices, limited to devices that match at least one of the
 * capability filters. Dictionary key is an IP address string, value is
 * a ConnectableDevice.
 */
- (NSDictionary *) compatibleDevices;

/**
 * Get all devices. Dictionary key is an IP address string,
 * value is a ConnectableDevice.
 */
- (NSDictionary *) allDevices;

// device/discovery registration
// @cond INTERNAL
- (void) registerDefaultServices;
- (void) registerDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass;
- (void) unregisterDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass;
// @endcond

/*!
 * A device will be displayed in the picker and compatible device list
 * if it matches any of the CapabilityFilter objects in this array.
 */
@property (nonatomic, strong) NSArray *capabilityFilters;

/*!
 * The pairingLevel property determines whether capabilities that
 * require pairing (such as entering a PIN) will be available.
 *
 * If pairingLevel is set to ConnectableDevicePairingLevelOn,
 * devices that require pairing will prompt the user to pair
 * when connecting to the device.
 *
 * If pairingLevel is set to ConnectableDevicePairingLevelOff (the default),
 * connecting to the device will avoid requiring pairing if possible
 * but some capabilities may not be available.
 */
@property (nonatomic) ConnectableDevicePairingLevel pairingLevel;

// control methods

/*!
 * Start scanning for devices on the local network.
 */
- (void) startDiscovery;

/*!
 * Stop scanning for devices.
 */
- (void) stopDiscovery;

// picker methods
/*!
 * Get a DevicePicker to show DiscoveryManager search results.
 * @return DevicePicker instance
 */
- (DevicePicker*) devicePicker;

/*!
 * ConnectableDeviceStore object which stores references to all discovered
 * devices. Pairing codes/keys, SSL certificates, recent access times, etc
 * are kept in the device store.
 *
 * ConnectableDeviceStore is a protocol which may be implemented as needed.
 * A default implementation, DefaultConnectableDeviceStore, exists for
 * convenience and will be used if no other device store is provided.
 *
 * In order to satisfy user privacy concerns, you should provide a UI element
 * in your app which exposes the ConnectableDeviceStore removeAll method.
 */
@property (nonatomic) id<ConnectableDeviceStore> deviceStore;

/*!
 * Whether pairing state will be automatically loaded/saved in the deviceStore.
 */
@property (nonatomic, readonly) BOOL useDeviceStore;

@end
