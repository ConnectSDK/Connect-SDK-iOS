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

#import "ZeroConfDiscoveryProvider_Private.h"
#import "ServiceDescription.h"
#import "CommonMacros.h"
#include <arpa/inet.h>


@interface ZeroConfDiscoveryProvider ()
{
    NSArray *_serviceFilters;
    NSTimer *_refreshTimer;
    NSMutableDictionary *_resolvingDevices;
    NSMutableDictionary *_discoveredDevices;
}

@end

@implementation ZeroConfDiscoveryProvider

- (void) startDiscovery
{
    if (self.isRunning)
        return;

    if (!_netServiceBrowser)
    {
        _netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        _netServiceBrowser.delegate = self;
    }

    if (_refreshTimer)
        [_refreshTimer invalidate];

    _resolvingDevices = [NSMutableDictionary new];
    _discoveredDevices = [NSMutableDictionary new];

    self.isRunning = YES;

    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(searchForServices) userInfo:nil repeats:YES];
    [_refreshTimer fire];
}

- (void) stopDiscovery
{
    if (!self.isRunning)
        return;

    if (_netServiceBrowser)
        [_netServiceBrowser stop];

    if (_refreshTimer)
    {
        [_refreshTimer invalidate];
        _refreshTimer = nil;
    }

    self.isRunning = NO;

    _resolvingDevices = [NSMutableDictionary new];
    _discoveredDevices = [NSMutableDictionary new];
}

- (void) searchForServices
{
    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *serviceFilter, NSUInteger idx, BOOL *stop)
    {
        NSString *filterType = serviceFilter[@"zeroconf"][@"filter"];

        if (filterType)
            [_netServiceBrowser searchForServicesOfType:filterType inDomain:@"local."];
    }];
}

- (void)addDeviceFilter:(NSDictionary *)parameters
{
    if (!_serviceFilters)
        _serviceFilters = [NSArray new];

    NSDictionary *ssdpInfo = [parameters objectForKey:@"zeroconf"];
    _assert_state(ssdpInfo != nil, @"This device filter does not have zeroconf discovery info");

    NSString *searchFilter = [ssdpInfo objectForKey:@"filter"];
    _assert_state(searchFilter != nil, @"The ssdp info for this device filter has no search filter parameter");

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
    if ([_resolvingDevices objectForKey:aNetService.name] || [_discoveredDevices objectForKey:aNetService.name])
        return;

    DLog(@"%@ : %@", aNetService.name, aNetService.domain);

    [aNetService setDelegate:self];
    [aNetService resolveWithTimeout:5.0];
    [_resolvingDevices setObject:aNetService forKey:aNetService.name];

    if (!moreComing)
        [aNetServiceBrowser stop];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if (![_discoveredDevices objectForKey:aNetService.name])
        return;

    DLog(@"%@", aNetService.name);

    ServiceDescription *serviceDescription = _discoveredDevices[aNetService.name];

    [_discoveredDevices removeObjectForKey:aNetService.name];

    if (self.delegate && [self.delegate respondsToSelector:@selector(discoveryProvider:didLoseService:)])
        [self.delegate discoveryProvider:self didLoseService:serviceDescription];

    if (!moreComing)
        [aNetServiceBrowser stop];
}

#pragma mark - NSNetServiceDelegate

/**
 * Parses the given address @c data (containing a @c sockaddr structure),
 * returning the IP address and transport port.
 * @note Only IPv4 addresses are supported.
 * @see <tt>-[NSNetService addresses]</tt>
 * @see Based on http://stackoverflow.com/a/18428117/2715
 * @param data    data containing a @c sockaddr structure; must not be @c nil.
 * @param address a pointer to a <tt>NSString *</tt> value where the parsed IP
 *                address will be placed; must not be @c nil.
 * @param port    a pointer to a @c uint16_t value where the parsed port will be
 *                placed; must not be @c nil.
 * @return @c YES if the parsing is successful and the output values are filled.
 */
- (BOOL)parseAddressData:(nonnull NSData *)data
           intoIPAddress:(out NSString ** __nonnull)outAddress
                 andPort:(out nonnull in_port_t *)outPort {
    NSParameterAssert(data);
    NSParameterAssert(outAddress);
    NSParameterAssert(outPort);

    BOOL success = NO;
    NSString *address;
    in_port_t port = 0;

    struct sockaddr *addressGeneric = (struct sockaddr *) [data bytes];
    switch (addressGeneric->sa_family) {
        case AF_INET: {
            struct sockaddr_in *ip4;
            char dest[INET_ADDRSTRLEN];
            ip4 = (struct sockaddr_in *) [data bytes];
            port = ntohs(ip4->sin_port);
            address = [NSString stringWithFormat: @"%s",
                       inet_ntop(AF_INET, &ip4->sin_addr, dest, sizeof dest)];
            success = YES;
            break;
        }

        default:
            break;
    }

    if (success) {
        *outAddress = address;
        *outPort = port;
    }

    return success;
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender
{
    sender.delegate = nil;
    [_resolvingDevices removeObjectForKey:sender.name];

    // according to Apple's docs, it is possible to have a service resolve with no addresses
    if (!sender.addresses || sender.addresses.count == 0)
    {
        DLog(@"%@ resolved with 0 addresses, bailing ...", sender.name);
        return;
    }

    __block BOOL foundIPv4Address = NO;
    __block NSString *address;
    __block in_port_t port = 0;
    [sender.addresses enumerateObjectsUsingBlock:^(NSData *addressData, NSUInteger idx, BOOL *stop) {
        if ((foundIPv4Address = [self parseAddressData:addressData
                                         intoIPAddress:&address
                                               andPort:&port])) {
            DLog(@"%@: resolved %@:%d", sender.name, address, port);
            *stop = YES;
        }
    }];

    if (!foundIPv4Address) {
        DLog(@"%@: couldn't find resolved IPv4 addresses (%ld total)",
             sender.name, (unsigned long)sender.addresses.count);
        return;
    }

    NSData *TXTRecordData = sender.TXTRecordData;
    NSString *TXTRecord = [[NSString alloc] initWithData:TXTRecordData encoding:NSUTF8StringEncoding];
    NSString *uuidIdentifier = @"deviceid=";
    NSRange UUIDRange = [TXTRecord rangeOfString:uuidIdentifier];

    NSString *UUID;

    if (UUIDRange.location == NSNotFound)
        UUID = sender.name;
    else
    {
        NSUInteger uuidStartLocation = UUIDRange.location + uuidIdentifier.length;
        NSUInteger macAddressLength = 14;

        UUID = [TXTRecord substringWithRange:NSMakeRange(uuidStartLocation, macAddressLength)];
    }

    NSString *serviceId = [self serviceIdFromFilter:sender.type];

    ServiceDescription *serviceDescription = [ServiceDescription descriptionWithAddress:address UUID:sender.name];
    serviceDescription.friendlyName = sender.name;
    serviceDescription.serviceId = serviceId;
    serviceDescription.port = (NSUInteger) port;
    serviceDescription.UUID = UUID;

    NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@/", address, @(port)];
    serviceDescription.commandURL = [NSURL URLWithString:commandPath];

    [_discoveredDevices setObject:serviceDescription forKey:sender.name];

    if (self.delegate && [self.delegate respondsToSelector:@selector(discoveryProvider:didFindService:)])
        [self.delegate discoveryProvider:self didFindService:serviceDescription];
}

- (void) netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
    DLog(@"%@", sender.name);
}

- (void) netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    DLog(@"%@ : %@", sender.name, errorDict);

    [_resolvingDevices removeObjectForKey:sender.name];
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
