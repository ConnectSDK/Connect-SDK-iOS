//
//  DiscoveryManagerDelegate.h
//  Connect SDK
//
//  Created by Jeremy White on 12/4/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DiscoveryManager;
@class ConnectableDevice;

@protocol DiscoveryManagerDelegate <NSObject>

@optional
- (void) discoveryManager:(DiscoveryManager *)manager didFindDevice:(ConnectableDevice *)device;
- (void) discoveryManager:(DiscoveryManager *)manager didLoseDevice:(ConnectableDevice *)device;
- (void) discoveryManager:(DiscoveryManager *)manager didUpdateDevice:(ConnectableDevice *)device;
- (void) discoveryManager:(DiscoveryManager *)manager didFailWithError:(NSError*)error;

@end
