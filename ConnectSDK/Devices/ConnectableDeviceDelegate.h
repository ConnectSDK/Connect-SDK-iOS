//
//  ConnectableDeviceDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
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

@class ConnectableDevice;
@class DeviceService;

/*!
 * ConnectableDeviceDelegate allows for a class to receive messages about ConnectableDevice connection, disconnect, and update events.
 *
 * It also serves as a delegate proxy for message handling when connecting and pairing with each of a ConnectableDevice's DeviceServices. Each of the DeviceService proxy methods are optional and would only be useful in a few use cases.
 * - providing your own UI for the pairing process.
 * - interacting directly and exclusively with a single type of DeviceService
 */
@protocol ConnectableDeviceDelegate <NSObject>

/*!
 * A ConnectableDevice sends out a ready message when all of its connectable DeviceServices have been connected and are ready to receive commands.
 *
 * @param device ConnectableDevice that is ready for commands.
 */
- (void) connectableDeviceReady:(ConnectableDevice *)device;

/*!
 * When all of a ConnectableDevice's DeviceServices have become disconnected, the disconnected message is sent.
 *
 * @param device ConnectableDevice that has been disconnected.
 */
- (void) connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error;

@optional

/*!
 * When a ConnectableDevice finds & loses DeviceServices, that ConnectableDevice will experience a change in its collective capabilities list. When such a change occurs, this message will be sent with arrays of capabilities that were added & removed.
 *
 * This message will allow you to decide when to stop/start interacting with a ConnectableDevice, based off of its supported capabilities.
 *
 * @param device ConnectableDevice that has experienced a change in capabilities
 * @param added NSArray of capabilities that are new to the ConnectableDevice
 * @param removed NSArray of capabilities that the ConnectableDevice has lost
 */
- (void) connectableDevice:(ConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed;

/*!
 * This method is called when the connection to the ConnectableDevice has failed.
 *
 * @param device ConnectableDevice that has failed to connect
 * @param error NSError with a description of the failure
 */
- (void) connectableDevice:(ConnectableDevice *)device connectionFailedWithError:(NSError *)error;

#pragma mark - DeviceService delegate proxy methods

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService requires an active connection. This will be the case for DeviceServices that send messages over websockets (webOS, etc) and DeviceServices that require pairing to send messages (Netcast, etc).
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService which requires a connection
 */
- (void) connectableDeviceConnectionRequired:(ConnectableDevice *)device forService:(DeviceService *)service;

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService has successfully connected.
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService which has connected
 */
- (void) connectableDeviceConnectionSuccess:(ConnectableDevice*)device forService:(DeviceService *)service;

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService becomes disconnected.
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService which has disconnected
 * @param error NSError with a description of any errors causing the disconnect. If this value is nil, then the disconnect was clean/expected.
 */
- (void) connectableDevice:(ConnectableDevice*)device service:(DeviceService *)service disconnectedWithError:(NSError*)error;

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService fails to connect.
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService which has failed to connect
 * @param error NSError with a description of the failure
 */
- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service didFailConnectWithError:(NSError*)error;

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService tries to connect and finds out that it requires pairing information from the user.
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService that requires pairing
 * @param pairingType DeviceServicePairingType that the DeviceService requires
 * @param pairingData Any data that might be required for the pairing process, will usually be nil
 */
- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingRequiredOfType:(int)pairingType withData:(id)pairingData;

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService completes the pairing process.
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService that has successfully completed pairing
 */
- (void) connectableDevicePairingSuccess:(ConnectableDevice*)device service:(DeviceService *)service;

/*!
 * DeviceService delegate proxy method.
 *
 * This method is called when a DeviceService fails to complete the pairing process.
 *
 * @param device ConnectableDevice containing the DeviceService
 * @param service DeviceService that has failed to complete pairing
 * @param error NSError with a description of the failure
 */
- (void) connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingFailedWithError:(NSError*)error;

@end
