//
// Created by Jeremy White on 3/21/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectableDevice.h"

/*!
 * ConnectableDeviceStore is a protocol which can be implemented to save key information about ConnectableDevices that have been discovered on the network. Any class which implements this protocol can be used as DiscoveryManager's deviceStore.
 *
 * The ConnectableDevice objects loaded from the ConnectableDeviceStore are for informational use only, and should not be interacted with. DiscoveryManager uses these ConnectableDevice objects to populate re-discovered ConnectableDevices with relevant data (last connected, pairing info, etc).
 *
 * A default implementation, DefaultConnectableDeviceStore, will be used by DiscoveryManager if no other ConnectableDeviceStore is provided to DiscoveryManager when startDiscovery is called.
 *
 * ###Privacy Considerations
 * If you chose to implement ConnectableDeviceStore, it is important to keep your users' privacy in mind.
 * - There should be UI elements in your app to
 *   + completely disable ConnectableDeviceStore
 *   + purge all data from ConnectableDeviceStore (removeAll)
 * - Your ConnectableDeviceStore implementation should
 *   + avoid tracking too much data (all discovered devices)
  *  + periodically remove ConnectableDevices from the ConnectableDeviceStore if they haven't been used/connected in X amount of time
 */
@protocol ConnectableDeviceStore <NSObject>

/*!
 * Add a ConnectableDevice to the ConnectableDeviceStore. If the ConnectableDevice is already stored, it's record will be updated.
 *
 * @param device ConnectableDevice to add to the ConnectableDeviceStore
 */
- (void) addDevice:(ConnectableDevice *)device;

/*!
 * Updates a ConnectableDevice's record in the ConnectableDeviceStore.
 *
 * @param device ConnectableDevice to update in the ConnectableDeviceStore
 */
- (void) updateDevice:(ConnectableDevice *)device;

/*!
 * Removes a ConnectableDevice's record from the ConnectableDeviceStore.
 *
 * @param device ConnectableDevice to remove from the ConnectableDeviceStore
 */
- (void) removeDevice:(ConnectableDevice *)device;

/*!
 * Clears out the ConnectableDeviceStore, removing all records.
 */
- (void) removeAll;

/*!
 * An array of all ConnectableDevices in the ConnectableDeviceStore. These ConnectableDevice objects are for informational use only, and should not be interacted with. DiscoveryManager uses these ConnectableDevice objects to populate discovered ConnectableDevices with relevant data (last connected, pairing info, etc).
 */
@property (nonatomic, readonly) NSArray *storedDevices;

@end
