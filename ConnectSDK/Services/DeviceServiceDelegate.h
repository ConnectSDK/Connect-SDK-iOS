//
//  DeviceServiceDelegate.h
//  Connect SDK
//
//  Created by Jeremy White on 12/23/13.
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

/*!
 * Type of pairing that is required by a particular DeviceService. This type will be passed along with the DeviceServiceDelegate deviceService:pairingRequiredOfType:withData: message.
 */
typedef enum {
    /*! DeviceService does not require pairing */
    DeviceServicePairingTypeNone = 0,

    /*! DeviceService requires user interaction on the first screen (ex. pairing alert) */
    DeviceServicePairingTypeFirstScreen,

    /*! First screen is displaying a pairing pin code that can be sent through the DeviceService */
    DeviceServicePairingTypePinCode,

    /*! DeviceService can pair with multiple pairing types (ex. first screen OR pin) */
    DeviceServicePairingTypeMixed,

    /*! DeviceService requires AirPlay mirroring to be enabled to connect */
    DeviceServicePairingTypeAirPlayMirroring,

    /*! DeviceService pairing type is unknown */
    DeviceServicePairingTypeUnknown
} DeviceServicePairingType;

@class DeviceService;


/*!
 * DeviceServiceDelegate allows your app to respond to each step of the connection and pairing processes, if needed. By default, a DeviceService's ConnectableDevice is set as the delegate. Changing a DeviceService's delegate will break the normal operation of Connect SDK and is discouraged. ConnectableDeviceDelegate provides proxy methods for all of the methods listed here.
 */
@protocol DeviceServiceDelegate <NSObject>

@optional

/*!
 * If the DeviceService requires an active connection (websocket, pairing, etc) this method will be called.
 *
 * @param service DeviceService that requires connection
 */
- (void) deviceServiceConnectionRequired:(DeviceService *)service;

/*!
 * After the connection has been successfully established, and after pairing (if applicable), this method will be called.
 *
 * @param service DeviceService that was successfully connected
 */
- (void) deviceServiceConnectionSuccess:(DeviceService*)service;

/*!
 * There are situations in which a DeviceService will update the capabilities it supports and propagate these changes to the DeviceService. Such situations include:
 * - on discovery, DIALService will reach out to detect if certain apps are installed
 * - on discovery, certain DeviceServices need to reach out for version & region information
 *
 * For more information on this particular method, see ConnectableDeviceDelegate's connectableDevice:capabilitiesAdded:removed: method.
 *
 * @param service DeviceService that has experienced a change in capabilities
 * @param added NSArray of capabilities that are new to the DeviceService
 * @param removed NSArray of capabilities that the DeviceService has lost
 */
- (void) deviceService:(DeviceService *)service capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed;

/*!
 * This method will be called on any disconnection. If error is nil, then the connection was clean and likely triggered by the responsible DiscoveryProvider or by the user.
 *
 * @param service DeviceService that disconnected
 * @param error NSError with a description of any errors causing the disconnect. If this value is nil, then the disconnect was clean/expected.
 */
- (void) deviceService:(DeviceService *)service disconnectedWithError:(NSError*)error;

/*!
 * Will be called if the DeviceService fails to establish a connection.
 *
 * @param service DeviceService which has failed to connect
 * @param error NSError with a description of the failure
 */
- (void) deviceService:(DeviceService *)service didFailConnectWithError:(NSError*)error;

/*!
 * If the DeviceService requires pairing, valuable data will be passed to the delegate via this method.
 *
 * @param service DeviceService that requires pairing
 * @param pairingType DeviceServicePairingType that the DeviceService requires
 * @param pairingData Any object/data that might be required for the pairing process, will usually be nil
 */
- (void) deviceService:(DeviceService *)service pairingRequiredOfType:(DeviceServicePairingType)pairingType withData:(id)pairingData;

/*!
 * This method will be called upon pairing success. On pairing success, a connection to the DeviceService will be attempted.
 *
 * @property service DeviceService that has successfully completed pairing
 */
- (void) deviceServicePairingSuccess:(DeviceService*)service;

/*!
 * If there is any error in pairing, this method will be called.
 *
 * @param service DeviceService that has failed to complete pairing
 * @param error NSError with a description of the failure
 */
- (void) deviceService:(DeviceService *)service pairingFailedWithError:(NSError*)error;

@end
