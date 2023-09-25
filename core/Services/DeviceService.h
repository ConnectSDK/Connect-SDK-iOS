//
//  DeviceService.h
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
#import "ServiceDescription.h"
#import "ServiceConfig.h"
#import "ConnectableDeviceDelegate.h"
#import "DeviceServiceDelegate.h"
#import "Capability.h"
#import "LaunchSession.h"

/*!
 * Enumerated value for determining how a DeviceService should handle pairing when attempting to connect.
 */
typedef enum {
    /*! DeviceServices will never try to pair with a device */
    DeviceServicePairingLevelOff = 0,
    
    /*! DeviceServices will try to pair with a device, if needed */
    DeviceServicePairingLevelOn
}DeviceServicePairingLevel;

/*!
 * Enumerated value for determining how a DeviceService should handle pairing when attempting to connect.
 */
typedef enum {
    /*! DeviceServices will never try to pair with a device */
    ConnectableDevicePairingLevelOff __attribute__((deprecated)) = DeviceServicePairingLevelOff,
    
    /*! DeviceServices will try to pair with a device, if needed */
    ConnectableDevicePairingLevelOn __attribute__((deprecated)) = DeviceServicePairingLevelOn
} ConnectableDevicePairingLevel;

/*!
 * ###Overview
 * From a high-level perspective, DeviceService completely abstracts the functionality of a particular service/protocol (webOS TV, Netcast TV, Chromecast, Roku, DIAL, etc).
 *
 * ###In Depth
 * DeviceService is an abstract class that is meant to be extended. You shouldn't ever use DeviceService directly, unless extending it to provide support for an additional service/protocol.
 *
 * Immediately after discovery of a DeviceService, DiscoveryManager will set the DeviceService's delegate to the ConnectableDevice that owns the DeviceService. You should not change the delegate unless you intend to manage the lifecycle of that service. The DeviceService will proxy all of its delegate method calls through the ConnectableDevice's ConnectableDeviceDelegate.
 *
 * ####Connection & Pairing
 * Your ConnectableDevice object will let you know if you need to connect or pair to any services.
 *
 * ####Capabilities
 * All DeviceService objects have a group of capabilities. These capabilities can be implemented by any object, and that object will be returned when you call the DeviceService's capability methods (launcher, mediaPlayer, volumeControl, etc).
 */
@interface DeviceService : NSObject <JSONObjectCoding>

/*!
 * Delegate object to receive DeviceService status messages. See note in the "In Depth" section about changing the DeviceServiceDelegate.
 */
@property (nonatomic, weak) id<DeviceServiceDelegate>delegate;

/*! Object containing the discovered information about this DeviceService */
@property (nonatomic, strong) ServiceDescription *serviceDescription;

/*! Object containing persistence data about this DeviceService (pairing info, SSL certificates, etc) */
@property (nonatomic, strong) ServiceConfig *serviceConfig;

/*! Name of the DeviceService (webOS, Chromecast, etc) */
@property (nonatomic, strong, readonly) NSString *serviceName;

/*!
 * A dictionary of keys/values that will be used by the DiscoveryProvider used to discover this DeviceService. Some keys that are used are: service name, SSDP filter, etc.
 */
+ (NSDictionary *) discoveryParameters;

/*!
 * Returns an instantiated DeviceService of the proper subclass (CastService, WebOSTVService, etc).
 *
 * @property _class DeviceService subclass to instantiate
 * @property serviceConfig ServiceConfig with configuration data of device (UUID, etc)
 */
+ (DeviceService *)deviceServiceWithClass:(Class)_class serviceConfig:(ServiceConfig *)serviceConfig;

/*!
 * Returns an instantiated DeviceService of the proper subclass (CastService, WebOSTVService, etc).
 *
 * @property serviceConfig ServiceConfig with configuration data of device (UUID, etc)
 */
- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig;

// @cond INTERNAL
+ (instancetype) deviceServiceWithJSONObject:(NSDictionary *)dict;
// @endcond

#pragma mark - Capabilities

/*!
 * An array of capabilities supported by the DeviceService. This array may change based off a number of factors.
 * - DiscoveryManager's pairingLevel value
 * - Connect SDK framework version
 * - First screen device OS version
 * - First screen device configuration (apps installed, settings, etc)
 * - Physical region
 */
@property (nonatomic, strong) NSArray *capabilities;

// @cond INTERNAL
- (void) updateCapabilities;
- (void) addCapability:(NSString *)capability;
- (void) addCapabilities:(NSArray *)capabilities;
- (void) removeCapability:(NSString *)capability;
- (void) removeCapabilities:(NSArray *)capabilities;
// @endcond

/*!
 * Test to see if the capabilities array contains a given capability. See the individual Capability classes for acceptable capability values.
 *
 * It is possible to append a wildcard search term `.Any` to the end of the search term. This method will return true for capabilities that match the term up to the wildcard.
 *
 * Example: `Launcher.App.Any`
 *
 * @property capability Capability to test against
 */
- (BOOL) hasCapability:(NSString *)capability;

/*!
 * Test to see if the capabilities array contains a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @property capabilities Array of capabilities to test against
 */
- (BOOL) hasCapabilities:(NSArray *)capabilities;

/*!
 * Test to see if the capabilities array contains at least one capability in a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @property capabilities Array of capabilities to test against
 */
- (BOOL) hasAnyCapability:(NSArray *)capabilities;

#pragma mark - Connection

/*! Whether the DeviceService is currently connected */
@property (nonatomic) BOOL connected;

/*! Whether the DeviceService requires an active connection or registration process */
@property (nonatomic, readonly) BOOL isConnectable;

/*!
 * Will attempt to connect to the DeviceService. The failure/success will be reported back to the DeviceServiceDelegate. If the connection attempt reveals that pairing is required, the DeviceServiceDelegate will also be notified in that event.
 */
- (void) connect;

/*!
 * Will attempt to disconnect from the DeviceService. The failure/success will be reported back to the DeviceServiceDelegate.
 */
- (void) disconnect;

# pragma mark - Pairing

/*! Whether the DeviceService requires pairing or not. */
@property (nonatomic, readonly) BOOL requiresPairing;

/*! Type of pairing that this DeviceService requires. May be unknown until you try to connect. */
@property (nonatomic, readwrite) DeviceServicePairingType pairingType;

/*! May contain useful information regarding pairing (pairing key length, etc) */
@property (nonatomic, readonly) id pairingData;

/*!
 * Will attempt to pair with the DeviceService with the provided pairingData. The failure/success will be reported back to the DeviceServiceDelegate.
 *
 * @param pairingData Data to be used for pairing. The type of this parameter will vary depending on what type of pairing is required, but is likely to be a string (pin code, pairing key, etc).
 */
- (void) pairWithData:(id)pairingData;

#pragma mark - Utility

/*!
 * Static property that determines whether a DeviceService subclass should shut down communication channels when the app enters a background state. This may be helpful for apps that need to communicate with web apps from the background. This property may not be applicable to all DeviceService subclasses.
 */
+ (BOOL) shouldDisconnectOnBackground;

/*!
 * Sets the shouldDisconnectOnBackground static property. This property should be set before starting DiscoveryManager for the first time.
 *
 * @property shouldDisconnectOnBackground New value for DeviceService.shouldDisconnectOnBackground
 */
+ (void) setShouldDisconnectOnBackround:(BOOL)shouldDisconnectOnBackground;

// @cond INTERNAL
void dispatch_on_main(dispatch_block_t block);
id ensureString(id value);
// @endcond

/*!
 * Every LaunchSession object has an associated DeviceService. Internally, LaunchSession's close method proxies to it's DeviceService's closeLaunchSession method. If, for some reason, your LaunchSession loses it's DeviceService reference, you can call this closeLaunchSession method directly.
 *
 * @param launchSession LaunchSession to be closed
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
