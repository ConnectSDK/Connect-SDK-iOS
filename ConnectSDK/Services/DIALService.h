//
//  DIALService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/13/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <ConnectSDK/ConnectSDK.h>
#import "Launcher.h"

@interface DIALService : DeviceService <ServiceCommandDelegate, Launcher>

/*!
 * Registers an app ID to be checked upon discovery of this device. If the app is found on the target device, the DIALService will gain the "Launcher.<appID>" capability, where <appID> is the value of the appId parameter.
 *
 * This method must be called before starting DiscoveryManager for the first time.
 *
 * @param appId ID of the app to be checked for
 */
+ (void) registerApp:(NSString *)appId;

@end
