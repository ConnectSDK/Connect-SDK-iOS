//
//  DiscoveryProviderDelegate.h
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

@class DiscoveryProvider;
@class ServiceDescription;

/*!
 * The DiscoveryProviderDelegate is mechanism for passing service information to the DiscoveryManager. You likely will not be using the DiscoveryProviderDelegate class directly, as DiscoveryManager acts as a delegate to all of the DiscoveryProviders.
 */
@protocol DiscoveryProviderDelegate <NSObject>

/*!
 * This method is called when the DiscoveryProvider discovers a service that matches one of its DeviceService filters. The ServiceDescription is created and passed to the delegate (which should be the DiscoveryManager). The ServiceDescription is used to create a DeviceService, which is then attached to a ConnectableDevice object.
 *
 * @param provider DiscoveryProvider that found the service
 * @param description ServiceDescription of the service that was found
 */
- (void) discoveryProvider:(DiscoveryProvider *)provider didFindService:(ServiceDescription *)description;

/*!
 * This method is called when the DiscoveryProvider's internal mechanism loses reference to a service that matches one of its DeviceService filters.
 *
 * @param provider DiscoveryProvider that lost the service
 * @param description ServiceDescription of the service that was lost
 */
- (void) discoveryProvider:(DiscoveryProvider *)provider didLoseService:(ServiceDescription *)description;

/*!
 * This method is called on any error/failure within the DiscoveryProvider.
 *
 * @param provider DiscoveryProvider that failed
 * @param error NSError providing a information about the failure
 */
- (void) discoveryProvider:(DiscoveryProvider *)provider didFailWithError:(NSError*)error;

@end
