//
//  DeviceService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServiceDescription.h"
#import "ServiceConfig.h"
#import "ConnectableDeviceDelegate.h"
#import "DeviceServiceDelegate.h"
#import "Capability.h"
#import "LaunchSession.h"

@interface DeviceService : NSObject <NSCoding>

@property (nonatomic, weak) id<DeviceServiceDelegate>delegate;
@property (nonatomic, strong) ServiceDescription *serviceDescription;
@property (nonatomic, strong) ServiceConfig *serviceConfig;
@property (nonatomic, strong, readonly) NSString *serviceName;

+ (NSDictionary *) discoveryParameters;
+ (DeviceService *)deviceServiceWithClass:(Class)class serviceConfig:(ServiceConfig *)serviceConfig;

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig;

#pragma mark - Capabilities

- (NSArray *) capabilities;
- (BOOL) hasCapability:(NSString *)capability;
- (BOOL) hasCapabilities:(NSArray *)capabilities;
- (BOOL) hasAnyCapability:(NSArray *)capabilities;

#pragma mark - Connection

@property (nonatomic) BOOL connected;

- (BOOL) isConnectable;
- (void) connect;
- (void) disconnect;

# pragma mark - Pairing

- (BOOL) requiresPairing;
- (DeviceServicePairingType) pairingType;
- (id) pairingData;
- (void) pairWithData:(id)pairingData;

#pragma mark - Utility

// @cond INTERNAL
void dispatch_on_main(dispatch_block_t block);
id ensureString(id value);
- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;
// @endcond

@end
