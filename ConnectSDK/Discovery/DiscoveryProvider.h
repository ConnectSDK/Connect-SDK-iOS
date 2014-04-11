//
//  DiscoveryProvider.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscoveryProviderDelegate.h"


/*!
 * ###Overview
 * From a high-level perspective, DiscoveryProvider completely abstracts the functionality of discovering services of a particular protocol (SSDP, Cast, etc). The DiscoveryProvider will pass service information to the DiscoveryManager, which will then create a DeviceService object and attach it to a ConnectableDevice object.
 *
 * ###In Depth
 * DiscoveryProvider is an abstract class that is meant to be extended. You shouldn't ever use DiscoveryProvider directly, unless extending it to provide support for another discovery protocol.
 *
 * By default, DiscoveryManager will set itself as a DiscoveryProvider's delegate. You should not change the delegate as it could cause unexpected inconsistencies within the discovery process.
 *
 * See CastDiscoveryProvider and SSDPDiscoveryProvider for implementations.
 */
@interface DiscoveryProvider : NSObject

/*! DiscoveryProviderDelegate, which should be the DiscoveryManager */
@property (nonatomic, weak) id<DiscoveryProviderDelegate> delegate;

/*! Whether or not the DiscoveryProvider is running */
@property (nonatomic) BOOL isRunning;

/*!
 * Whether or not the DiscoveryProvider has any services it is supposed to be searching for. If YES, then the DiscoveryProvider will be stopped and de-referenced by the DiscoveryManager.
 */
@property (nonatomic, readonly) BOOL isEmpty;

/*!
 * Adds a device filter for a particular DeviceService.
 *
 * @param parameters Parameters to be used for discovering a particular DeviceService
 */
- (void) addDeviceFilter:(NSDictionary *)parameters;

/*!
 * Removes a device filter for a particular DeviceService. If the DiscoveryProvider has no other devices to be searching for, the DiscoveryProvider will be stopped and de-referenced.
 *
 * @param parameters Parameters to be used for discovering a particular DeviceService
 */
- (void) removeDeviceFilter:(NSDictionary *)parameters;

/*!
 * Starts the DiscoveryProvider.
 */
- (void) startDiscovery;

/*!
 * Stops the DiscoveryProvider.
 */
- (void) stopDiscovery;

@end
