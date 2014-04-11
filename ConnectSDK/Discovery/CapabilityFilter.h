//
// Created by Jeremy White on 1/29/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConnectableDevice.h"


@interface CapabilityFilter : NSObject

/*!
 * Capabilities required by this filter
 */
@property (nonatomic, strong, readonly) NSArray *capabilities;

/*!
 * Create a CapabilityFilter with the given required capabilities
 */
+ (CapabilityFilter *)filterWithCapabilities:(NSArray *)capabilities;

/*!
 * Add required capabilities to the filter.
 * @param capability Capability to add
 */
- (void)addCapability:(NSString *)capability;

/*!
 * Add required capabilities to the filter.
 * @param capabilities list of capability names
 */
- (void)addCapabilities:(NSArray *)capabilities;

@end
