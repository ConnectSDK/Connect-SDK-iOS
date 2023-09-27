//
//  ConnectableDeviceStore.h
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

#import <Foundation/Foundation.h>
#import "ConnectableDevice.h"

/*!
 * ConnectableDeviceStore is a protocol which can be implemented to save key information about ConnectableDevices that have been connected to. Any class which implements this protocol can be used as DiscoveryManager's deviceStore.
 *
 * A default implementation, DefaultConnectableDeviceStore, will be used by DiscoveryManager if no other ConnectableDeviceStore is provided to DiscoveryManager when startDiscovery is called.
 *
 * ###Privacy Considerations
 * If you chose to implement ConnectableDeviceStore, it is important to keep your users' privacy in mind.
 * - There should be UI elements in your app to
 *   + completely disable ConnectableDeviceStore
 *   + purge all data from ConnectableDeviceStore (removeAll)
 * - Your ConnectableDeviceStore implementation should
 *   + avoid tracking too much data (indefinitely storing all discovered devices)
 *   + periodically remove ConnectableDevices from the ConnectableDeviceStore if they haven't been used/connected in X amount of time
 */
@protocol ConnectableDeviceStore <NSObject>

/*!
 * Add a ConnectableDevice to the ConnectableDeviceStore. If the ConnectableDevice is already stored, it's record will be updated.
 *
 * @param device ConnectableDevice to add to the ConnectableDeviceStore
 */
- (void) addDevice:(ConnectableDevice *)device;

/*!
 * Updates a ConnectableDevice's record in the ConnectableDeviceStore. If the ConnectableDevice is not in the store, this call will be ignored.
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
 * Gets a ConnectableDevice object for a provided id. The id may be for the ConnectableDevice object or any of the device's DeviceServices.
 *
 * @param id Unique ID for a ConnectableDevice or any of its DeviceService objects
 *
 * @return ConnectableDevice object if a matching id was found, otherwise will return nil
 */
- (ConnectableDevice *) deviceForId:(NSString *)id;

/*!
 * Gets a ServiceConfig object for a provided UUID. This is used by DiscoveryManager to retain crucial service information between sessions (pairing code, etc).
 *
 * @param UUID Unique ID for the service
 *
 * @return ServiceConfig object if a matching UUID was found, otherwise will return nil
 */
- (ServiceConfig *) serviceConfigForUUID:(NSString *)UUID;

/*!
 * Clears out the ConnectableDeviceStore, removing all records.
 */
- (void) removeAll;

/*!
 * A dictionary containing information about all ConnectableDevices in the ConnectableDeviceStore. To get a strongly-typed ConnectableDevice object, use the `getDeviceForUUID:` method.
 */
@property (nonatomic, readonly) NSDictionary *storedDevices;

@end
