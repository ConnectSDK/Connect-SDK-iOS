//
//  DelegateMock.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-08-13.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DelegateMock.h"

@implementation DelegateMock

- (void)discoveryProvider:(DiscoveryProvider *)provider
           didFindService:(ServiceDescription *)description {
    self.capturedServiceDescription = description;
    [self.exp fulfill];
}

@end

