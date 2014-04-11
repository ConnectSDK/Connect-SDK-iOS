//
//  DiscoveryProviderDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DiscoveryProvider;
@class ServiceDescription;

@protocol DiscoveryProviderDelegate <NSObject>

- (void) discoveryProvider:(DiscoveryProvider *)provider didFindService:(ServiceDescription *)description;
- (void) discoveryProvider:(DiscoveryProvider *)provider didLoseService:(ServiceDescription *)description;
- (void) discoveryProvider:(DiscoveryProvider *)provider didFailWithError:(NSError*)error;

@end
