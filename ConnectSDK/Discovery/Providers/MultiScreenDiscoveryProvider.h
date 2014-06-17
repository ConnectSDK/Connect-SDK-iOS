//
// Created by Jeremy White on 6/16/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscoveryProvider.h"


@interface MultiScreenDiscoveryProvider : DiscoveryProvider

@property (nonatomic, readonly, copy) void (^findDevicesCallback)(NSArray  *);
@property (nonatomic, readonly) NSDictionary *devices;

@end
