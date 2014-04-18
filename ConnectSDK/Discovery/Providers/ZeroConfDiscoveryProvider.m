//
//  ZeroConfDiscoveryProvider.m
//  Connect SDK
//
//  Created by Jeremy White on 4/18/14.
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

#import "ZeroConfDiscoveryProvider.h"
#import "ServiceDescription.h"


@interface ZeroConfDiscoveryProvider () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
{
    NSNetServiceBrowser *_netServiceBrowser;
    NSArray *_serviceFilters;
    NSTimer *_refreshTimer;
}

@end

@implementation ZeroConfDiscoveryProvider

- (void) startDiscovery
{
    if (!_netServiceBrowser)
    {
        _netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        _netServiceBrowser.delegate = self;
    }

    if (_refreshTimer)
        [_refreshTimer invalidate];

    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(searchForServices) userInfo:nil repeats:YES];
    [_refreshTimer fire];
}

- (void) stopDiscovery
{
    if (_netServiceBrowser)
        [_netServiceBrowser stop];

    if (_refreshTimer)
    {
        [_refreshTimer invalidate];
        _refreshTimer = nil;
    }
}

- (void) searchForServices
{
    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *serviceFilter, NSUInteger idx, BOOL *stop)
    {
        NSString *filterType = serviceFilter[@"zeroconf"][@"filter"];

        if (filterType)
            [_netServiceBrowser searchForServicesOfType:filterType inDomain:nil];
    }];
}

- (void)addDeviceFilter:(NSDictionary *)parameters
{
    if (!_serviceFilters)
        _serviceFilters = [NSArray new];

    NSDictionary *ssdpInfo = [parameters objectForKey:@"zeroconf"];
    NSAssert(ssdpInfo != nil, @"This device filter does not have zeroconf discovery info");

    NSString *searchFilter = [ssdpInfo objectForKey:@"filter"];
    NSAssert(searchFilter != nil, @"The ssdp info for this device filter has no search filter parameter");

    _serviceFilters = [_serviceFilters arrayByAddingObject:parameters];
}

- (void)removeDeviceFilter:(NSDictionary *)parameters
{
    NSString *searchTerm = [parameters objectForKey:@"serviceId"];
    __block BOOL shouldRemove = NO;
    __block NSUInteger removalIndex;

    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *searchFilter, NSUInteger idx, BOOL *stop) {
        NSString *serviceId = [searchFilter objectForKey:@"serviceId"];

        if ([serviceId isEqualToString:searchTerm])
        {
            shouldRemove = YES;
            removalIndex = idx;
            *stop = YES;
        }
    }];

    if (shouldRemove)
    {
        NSMutableArray *mutableFilters = [NSMutableArray arrayWithArray:_serviceFilters];
        [mutableFilters removeObjectAtIndex:removalIndex];
        _serviceFilters = [NSArray arrayWithArray:mutableFilters];
    }
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"netServiceBrowser didFindService %@ : %@", aNetService.name, aNetService.domain);

    NSString *serviceId = [self serviceIdFromFilter:aNetService.type];

    ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:@"0.0.0.0" UUID:aNetService.name];
    serviceDescription.friendlyName = aNetService.name;
    serviceDescription.serviceId = serviceId;

    if (self.delegate && [self.delegate respondsToSelector:@selector(discoveryProvider:didFindService:)])
        [self.delegate discoveryProvider:self didFindService:serviceDescription];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"netServiceBrowser didRemoveService %@", aNetService.name);

    NSString *serviceId = [self serviceIdFromFilter:aNetService.type];

    ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:@"0.0.0.0" UUID:aNetService.name];
    serviceDescription.friendlyName = aNetService.name;
    serviceDescription.serviceId = serviceId;

    if (self.delegate && [self.delegate respondsToSelector:@selector(discoveryProvider:didLoseService:)])
        [self.delegate discoveryProvider:self didLoseService:serviceDescription];
}

#pragma mark - Helper methods

- (NSString *)serviceIdFromFilter:(NSString *)filter
{
    if (!filter || filter.length == 0)
        return nil;

    __block NSString *serviceId;

    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *serviceFilter, NSUInteger idx, BOOL *stop)
    {
        NSString *serviceFilterType = serviceFilter[@"zeroconf"][@"filter"];

        if ([filter rangeOfString:serviceFilterType].location != NSNotFound)
        {
            serviceId = serviceFilter[@"serviceId"];
            *stop = YES;
        }
    }];

    return serviceId;
}

@end
