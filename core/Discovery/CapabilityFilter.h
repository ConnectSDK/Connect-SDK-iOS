//
//  CapabilityFilter.h
//  Connect SDK
//
//  Created by Jeremy White on 1/29/14.
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
 * CapabilityFilter is an object that wraps an NSArray of required capabilities. This CapabilityFilter is used for determining which devices will appear in DiscoveryManager's compatibleDevices array. The contents of a CapabilityFilter's array must be any of the string constants defined in the Capability header files.
 *
 * ###CapabilityFilter values
 * Here are some examples of values for the Capability constants.
 *
 * - kMediaPlayerPlayVideo = "MediaPlayer.Display.Video"
 * - kMediaPlayerDisplayImage = "MediaPlayer.Display.Image"
 * - kVolumeControlSubscribe = "VolumeControl.Subscribe"
 * - kMediaControlAny = "Media.Control.Any"
 *
 * All Capability header files also define a constant array of all capabilities defined in that header (ex. kVolumeControlCapabilities).
 *
 * ###AND/OR Filtering
 * CapabilityFilter is an AND filter. A ConnectableDevice would need to satisfy all conditions of a CapabilityFilter to pass.
 *
 * [DiscoveryManager capabilityFilters] is an OR filter. a ConnectableDevice only needs to satisfy one condition (CapabilityFilter) to pass.
 *
 * ###Examples
 * Filter for all devices that support video playback AND any media controls AND volume up/down.
 *
@code
    NSArray *capabilities = @[
        kMediaPlayerPlayVideo,
        kMediaControlAny,
        kVolumeControlVolumeUpDown
    ];

    CapabilityFilter *filter =
        [CapabilityFilter filterWithCapabilities:capabilities];

    [[DiscoveryManager sharedManager] setCapabilityFilters:@[filter]];
@endcode
 *
 * Filter for all devices that support (video playback AND any media controls AND volume up/down) OR (image display).
 *
@code
    NSArray *videoCapabilities = @[
        kMediaPlayerPlayVideo,
        kMediaControlAny,
        kVolumeControlVolumeUpDown
    ];

    NSArray *imageCapabilities = @[
        kMediaPlayerDisplayImage
    ];

    CapabilityFilter *videoFilter =
        [CapabilityFilter filterWithCapabilities:videoCapabilities];
    CapabilityFilter *imageFilter =
        [CapabilityFilter filterWithCapabilities:imageCapabilities];

    [[DiscoveryManager sharedManager] setCapabilityFilters:@[videoFilter, imageFilter]];
@endcode
 */
@interface CapabilityFilter : NSObject

/*!
 * Array of capabilities required by this filter. This property is readonly -- use the addCapability or addCapabilities to build this object.
 */
@property (nonatomic, strong, readonly) NSArray *capabilities;

/*!
 * Create a CapabilityFilter with the given array required capabilities.
 *
 * @param capabilities Capabilities to be added to the new filter
 */
+ (CapabilityFilter *)filterWithCapabilities:(NSArray *)capabilities;

/*!
 * Add a required capability to the filter.
 *
 * @param capability Capability name to add (see capability header files for NSString constants)
 */
- (void)addCapability:(NSString *)capability;

/*!
 * Add array of required capabilities to the filter.
 *
 * @param capabilities List of capability names (see capability header files for NSString constants)
 */
- (void)addCapabilities:(NSArray *)capabilities;

@end
