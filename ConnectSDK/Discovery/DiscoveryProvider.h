//
//  DiscoveryProvider.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DiscoveryProviderDelegate.h"

@interface DiscoveryProvider : NSObject
{
    NSMutableArray *_deviceFilters;
}

@property (nonatomic, weak) id<DiscoveryProviderDelegate> delegate;
@property (nonatomic) BOOL isRunning;

- (void) addDeviceFilter:(NSDictionary *)parameters;
- (void) removeDeviceFilter:(NSDictionary *)parameters;
- (BOOL) isEmpty;

- (void) startDiscovery;
- (void) stopDiscovery;

@end
