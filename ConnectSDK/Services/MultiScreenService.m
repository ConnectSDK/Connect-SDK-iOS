//
// Created by Jeremy White on 6/16/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "MultiScreenService.h"
#import "DiscoveryManager.h"
#import "MultiScreenDiscoveryProvider.h"
#import "ConnectError.h"

@implementation MultiScreenService

+ (NSDictionary *) discoveryParameters
{
    return @{
        @"serviceId" : kConnectSDKMultiScreenTVServiceId
    };
}

- (void) setServiceDescription:(ServiceDescription *)serviceDescription
{
    if (!serviceDescription)
        return;

    [super setServiceDescription:serviceDescription];

    _device = [self deviceForAddress:serviceDescription.address];
}

- (MSDevice *) deviceForAddress:(NSString *)address
{
    if (!address || address.length == 0)
        return nil;

    __block MSDevice *device;

    [[DiscoveryManager sharedManager].discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *provider, NSUInteger idx, BOOL *stop) {
        if ([provider isKindOfClass:[MultiScreenDiscoveryProvider class]])
        {
            MultiScreenDiscoveryProvider *multiScreenProvider = (MultiScreenDiscoveryProvider *) provider;
            device = multiScreenProvider.devices[address];
            *stop = YES;
        }
    }];

    return device;
}

- (void) connect
{
    if (!_device)
    {
        NSError *connectError = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Was unable to find the MSDevice instance for this IP address"];

        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)])
            dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:connectError]; });

        return;
    }

    self.connected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) disconnect
{
    self.connected = NO;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

#pragma mark - Web App Launcher

@end
