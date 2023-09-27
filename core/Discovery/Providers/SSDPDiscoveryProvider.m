//
//  SSDPDiscoveryProvider.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
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

#import <UIKit/UIKit.h>
#import "SSDPDiscoveryProvider_Private.h"
#import "ServiceDescription.h"
#import "CTXMLReader.h"
#import "DeviceService.h"
#import "CommonMacros.h"

#import <sys/utsname.h>

#define kSSDP_multicast_address @"239.255.255.250"
#define kSSDP_port 1900

// credit: http://stackoverflow.com/a/1108927/2715
NSString* machineName()
{
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@interface SSDPDiscoveryProvider() <NSXMLParserDelegate>
{
    NSString *_ssdpHostName;

    NSArray *_serviceFilters;
    NSMutableDictionary *_foundServices;

    NSTimer *_refreshTimer;

    NSMutableDictionary *_helloDevices;
    NSOperationQueue *_locationLoadQueue;
}

@end

@implementation SSDPDiscoveryProvider

static double refreshTime = 10.0;
static double searchAttemptsBeforeKill = 6.0;

#pragma mark - Setup/creation

- (instancetype) init
{
    self = [super init];
    
    if (self)
    {
        _ssdpHostName = [NSString stringWithFormat:@"%@:%d", kSSDP_multicast_address, kSSDP_port];

        _foundServices = [[NSMutableDictionary alloc] init];
        _serviceFilters = [[NSMutableArray alloc] init];
        
        _locationLoadQueue = [[NSOperationQueue alloc] init];
        _locationLoadQueue.maxConcurrentOperationCount = 10;
        
        self.isRunning = NO;
    }
    
    return self;
}

#pragma mark - Control methods

- (void) startDiscovery
{
    if (!self.isRunning)
    {
        self.isRunning = YES;
        [self start];
    }
}

- (void) stopDiscovery
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (_refreshTimer)
        [_refreshTimer invalidate];
    
    if (_searchSocket)
        [_searchSocket close];

    if (_multicastSocket)
        [_multicastSocket close];

    _foundServices = [NSMutableDictionary new];
    _helloDevices = [NSMutableDictionary new];
    [_locationLoadQueue cancelAllOperations];
    
    self.isRunning = NO;
    
    _searchSocket = nil;
    _multicastSocket = nil;
    _refreshTimer = nil;
}

- (void) start
{
    if (_refreshTimer == nil)
    {
        _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshTime target:self selector:@selector(sendSearchRequests:) userInfo:nil repeats:YES];
        
        [self sendSearchRequests:NO];
    }
}

#pragma mark - Device filter management

- (void)addDeviceFilter:(NSDictionary *)parameters
{
    NSDictionary *ssdpInfo = [parameters objectForKey:@"ssdp"];
    _assert_state(ssdpInfo != nil, @"This device filter does not have ssdp discovery info");
    
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

#pragma mark - SSDP M-SEARCH Request

- (void) sendSearchRequests:(BOOL)shouldKillInactiveDevices
{
    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *info, NSUInteger idx, BOOL *stop) {
        NSDictionary *ssdpInfo = [info objectForKey:@"ssdp"];
        NSString *searchFilter = [ssdpInfo objectForKey:@"filter"];
        NSString *userAgentToken = [ssdpInfo objectForKey:@"userAgentToken"];
        
        [self sendRequestForFilter:searchFilter userAgentToken:userAgentToken killInactiveDevices:shouldKillInactiveDevices];
    }];
}

- (void) sendRequestForFilter:(NSString *)filter userAgentToken:(NSString *)userAgentToken killInactiveDevices:(BOOL)shouldKillInactiveDevices
{
    if (shouldKillInactiveDevices)
    {
        BOOL refresh = NO;
        NSMutableArray *killKeys = [NSMutableArray array];
        
        // 6 detection attempts, if still not present then kill it.
        double killPoint = [[NSDate date] timeIntervalSince1970] - (refreshTime * searchAttemptsBeforeKill);

        @synchronized (_foundServices)
        {
            for (NSString *key in _foundServices)
            {
                ServiceDescription *service = (ServiceDescription *) [_foundServices objectForKey:key];

                if (service.lastDetection < killPoint)
                {
                    [killKeys addObject:key];
                    refresh = YES;
                }
            }

            if (refresh)
            {
                [killKeys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop)
                {
                    ServiceDescription *service = [_foundServices objectForKey:key];

                    [self notifyDelegateOfLostService:service];

                    [_foundServices removeObjectForKey:key];
                }];
            }
        }
    }
    
    CFHTTPMessageRef theSearchRequest = CFHTTPMessageCreateRequest(NULL, CFSTR("M-SEARCH"),
                                                                   (__bridge  CFURLRef)[NSURL URLWithString: @"*"], kCFHTTPVersion1_1);
    CFHTTPMessageSetHeaderFieldValue(theSearchRequest, CFSTR("HOST"), (__bridge  CFStringRef) _ssdpHostName);
    CFHTTPMessageSetHeaderFieldValue(theSearchRequest, CFSTR("MAN"), CFSTR("\"ssdp:discover\""));
    CFHTTPMessageSetHeaderFieldValue(theSearchRequest, CFSTR("MX"), CFSTR("5"));
    CFHTTPMessageSetHeaderFieldValue(theSearchRequest, CFSTR("ST"),  (__bridge  CFStringRef)filter);
    CFHTTPMessageSetHeaderFieldValue(theSearchRequest, CFSTR("USER-AGENT"), (__bridge CFStringRef)[self userAgentForToken:userAgentToken]);

    NSData *message = CFBridgingRelease(CFHTTPMessageCopySerializedMessage(theSearchRequest));
    
    if (!_searchSocket)
    {
		_searchSocket = [[SSDPSocketListener alloc] initWithAddress:kSSDP_multicast_address andPort:0];
		_searchSocket.delegate = self;
        [_searchSocket open];
    }

    if (!_multicastSocket)
    {
		_multicastSocket = [[SSDPSocketListener alloc] initWithAddress:kSSDP_multicast_address andPort:kSSDP_port];
		_multicastSocket.delegate = self;
        [_multicastSocket open];
    }

    [_searchSocket sendData:message toAddress:kSSDP_multicast_address andPort:kSSDP_port];
    [self performBlock:^{ [_searchSocket sendData:message toAddress:kSSDP_multicast_address andPort:kSSDP_port]; } afterDelay:1];
    [self performBlock:^{ [_searchSocket sendData:message toAddress:kSSDP_multicast_address andPort:kSSDP_port]; } afterDelay:2];
    
    CFRelease(theSearchRequest);
}

#pragma mark - M-SEARCH Response Processing

//* UDPSocket-delegate-method handle anew messages
//* All messages from devices handling here
- (void)socket:(SSDPSocketListener *)aSocket didReceiveData:(NSData *)aData fromAddress:(NSString *)anAddress
{
    // Try to create a HTTPMessage from received data.
    
	CFHTTPMessageRef theHTTPMessage = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
	CFHTTPMessageAppendBytes(theHTTPMessage, aData.bytes, aData.length);

    // We awaiting for receiving a complete header. If it not - just skip it.
	if (CFHTTPMessageIsHeaderComplete(theHTTPMessage))
	{
        
        // Receive some important data from the header
		NSString *theRequestMethod = CFBridgingRelease (CFHTTPMessageCopyRequestMethod(theHTTPMessage));
		NSInteger theCode = CFHTTPMessageGetResponseStatusCode(theHTTPMessage);
		NSDictionary *theHeaderDictionary = CFBridgingRelease(CFHTTPMessageCopyAllHeaderFields(theHTTPMessage));
        
		BOOL isNotify = [theRequestMethod isEqualToString:@"NOTIFY"];
		NSString *theType = (isNotify) ? theHeaderDictionary[@"NT"] : theHeaderDictionary[@"ST"];
        
        // There is 3 possible methods in SSDP:
        // 1) M-SEARCH - for search requests - skip it
        // 2) NOTIFY - for devices notification: advertisements ot bye-bye
        // 3) * with CODE 200 - answer for M-SEARCH request
        
        // Obtain a unique service id ID - USN.
        NSString *theUSSNKey = theHeaderDictionary[@"USN"];

        if ((theCode == 200) &&
            ![theRequestMethod isEqualToString:@"M-SEARCH"] &&
            [self isSearchingForFilter:theType] &&
            (theUSSNKey.length > 0))
        {
            //Extract the UUID
            NSRegularExpression *reg = [[NSRegularExpression alloc] initWithPattern:@"(?:uuid:).*(?:::)" options:0 error:nil];
            NSString *theUUID;
            NSTextCheckingResult *match = [reg firstMatchInString:theUSSNKey options:0 range:NSMakeRange(0, [theUSSNKey length])];
            
            NSRange range = [match rangeAtIndex:0];
            range.location = range.location + 5;
            range.length = MIN(range.length - 7, (theUSSNKey.length -range.location));
            theUUID = [theUSSNKey substringWithRange:range];
            
            if (theUUID && theUUID.length > 0)
            {
                // If it is a NOTIFY - byebye message - try to find a device from a list and send him byebye
                if ([theHeaderDictionary[@"NTS"] isEqualToString:@"ssdp:byebye"])
                {
                    @synchronized (_foundServices)
                    {
                        ServiceDescription *theService = _foundServices[theUUID];

                        if (theService != nil)
                        {
                            [self notifyDelegateOfLostService:theService];

                            [_foundServices removeObjectForKey:theUUID];

                            theService = nil;
                        }
                    }
                } else
                {
                    NSString *location = [theHeaderDictionary objectForKey:@"Location"];

                    if (location && location.length > 0)
                    {
                        // Advertising or search-respond
                        // Try to figure out if the device has been dicovered yet
                        ServiceDescription *foundService;
                        ServiceDescription *helloService;

                        @synchronized(_foundServices) { foundService = [_foundServices objectForKey:theUUID]; }
                        @synchronized(_helloDevices) { helloService = [_helloDevices objectForKey:theUUID]; }

                        BOOL isNew = NO;

                        // If it isn't  - create a new device object and add it to device list
                        if (foundService == nil && helloService == nil)
                        {
                            foundService = [[ServiceDescription alloc] init];
                            //Check that this is what is wanted
                            foundService.UUID = theUUID;
                            foundService.type =  theType;

                            NSURL* url = [NSURL URLWithString:location];

                            if (url && url.scheme && url.host)
                            {
                                foundService.address = url.host;
                            } else
                            {
                                foundService.address = anAddress;
                            }

                            foundService.port = 3001;
                            isNew = YES;
                        }

                        foundService.lastDetection = [[NSDate date] timeIntervalSince1970];

                        // If device - newly-created one notify about it's discovering
                        if (isNew)
                        {
                            @synchronized (_helloDevices)
                            {
                                if (_helloDevices == nil)
                                    _helloDevices = [NSMutableDictionary dictionary];

                                [_helloDevices setObject:foundService forKey:theUUID];
                            }

                            [self getLocationData:location forKey:theUUID andType:theType];
                        }
                    }
                }
            }
		}
	}
    
	CFRelease(theHTTPMessage);
}

- (void) getLocationData:(NSString*)url forKey:(NSString*)UUID andType:(NSString *)theType
{
    NSURL *req = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:req];
    [NSURLConnection sendAsynchronousRequest:request queue:_locationLoadQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSError *xmlError;
        NSDictionary *xml = [CTXMLReader dictionaryForXMLData:data error:&xmlError];

        if (!xmlError)
        {
            NSDictionary *device = [self device:[xml valueForKeyPath:@"root.device"]
                   containingServicesWithFilter:theType];

            if (device)
            {
                ServiceDescription *service;
                @synchronized(_helloDevices) { service = [_helloDevices objectForKey:UUID]; }

                if (service)
                {
                    service.type = theType;
                    service.friendlyName = [device valueForKeyPath:@"friendlyName.text"];
                    service.modelName = [[device objectForKey:@"modelName"] objectForKey:@"text"];
                    service.modelNumber = [[device objectForKey:@"modelNumber"] objectForKey:@"text"];
                    service.modelDescription = [[device objectForKey:@"modelDescription"] objectForKey:@"text"];
                    service.manufacturer = [[device objectForKey:@"manufacturer"] objectForKey:@"text"];
                    service.locationXML = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    service.serviceList = [self serviceListForDevice:device];
                    service.commandURL = response.URL;
                    service.locationResponseHeaders = [((NSHTTPURLResponse *)response) allHeaderFields];

                    @synchronized(_foundServices) { [_foundServices setObject:service forKey:UUID]; }

                    [self notifyDelegateOfNewService:service];
                }
            }
        }
        
        @synchronized(_helloDevices) { [_helloDevices removeObjectForKey:UUID]; }
    }];
}

- (void) notifyDelegateOfNewService:(ServiceDescription *)service
{
    NSArray *serviceIds = [self serviceIdsForFilter:service.type];

    [serviceIds enumerateObjectsUsingBlock:^(NSString *serviceId, NSUInteger idx, BOOL *stop) {
        ServiceDescription *newService = [service copy];
        newService.serviceId = serviceId;

        dispatch_on_main(^{ [self.delegate discoveryProvider:self didFindService:newService]; });
    }];
}

- (void) notifyDelegateOfLostService:(ServiceDescription *)service
{
    NSArray *serviceIds = [self serviceIdsForFilter:service.type];

    [serviceIds enumerateObjectsUsingBlock:^(NSString *serviceId, NSUInteger idx, BOOL *stop) {
        ServiceDescription *newService = [service copy];
        newService.serviceId = serviceId;

        dispatch_on_main(^{ [self.delegate discoveryProvider:self didLoseService:newService]; });
    }];
}

#pragma mark - Helper methods

- (BOOL) isSearchingForFilter:(NSString *)filter
{
    __block BOOL containsFilter = NO;

    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *serviceFilter, NSUInteger idx, BOOL *stop) {
        NSString *ssdpFilter = [[serviceFilter objectForKey:@"ssdp" ] objectForKey:@"filter"];
        
        if ([ssdpFilter isEqualToString:filter])
        {
            containsFilter = YES;
            *stop = YES;
        }
    }];
    
    return containsFilter;
}

/// Returns the required services strings array for the given registered filter,
/// or @c nil.
- (NSArray *)requiredServicesForFilter:(NSString *)filter {
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"%K LIKE %@",
                                    @"ssdp.filter", filter];
    NSDictionary *serviceFilter = [_serviceFilters filteredArrayUsingPredicate:filterPredicate].firstObject;
    return [serviceFilter valueForKeyPath:@"ssdp.requiredServices"];
}

/// Returns the discovered services strings array for the given XML device
/// description, or @c nil.
- (NSArray *)discoveredServicesInDevice:(NSDictionary *)device {
    id serviceList = [device valueForKeyPath:@"serviceList.service"];
    NSArray *discoveredServices;
    NSString *const kServiceTypeKeyPath = @"serviceType.text";

    if ([serviceList isKindOfClass:[NSDictionary class]]) {
        discoveredServices = [NSArray arrayWithObject:[serviceList valueForKeyPath:kServiceTypeKeyPath]];
    } else if ([serviceList isKindOfClass:[NSArray class]]) {
        discoveredServices = [serviceList valueForKeyPath:kServiceTypeKeyPath];
    }

    return discoveredServices;
}

/// Returns YES if all of the required services are available among the
/// discovered ones.
- (BOOL)allRequiredServices:(NSArray *)requiredServices
    areInDiscoveredServices:(NSArray *)discoveredServices {
    NSSet *requiredServicesSet = [NSSet setWithArray:requiredServices];
    NSSet *discoveredServicesSet = [NSSet setWithArray:discoveredServices];
    return [requiredServicesSet isSubsetOfSet:discoveredServicesSet];
}

/// Returns a device description that contains the given required services. It
/// may be the root device or any of the subdevices. If no device matches,
/// returns @c nil.
- (NSDictionary *)device:(NSDictionary *)device
containingRequiredServices:(NSArray *)requiredServices {
    NSArray *discoveredServices = [self discoveredServicesInDevice:device];
    const BOOL deviceHasAllRequiredServices = [self allRequiredServices:requiredServices
                                                areInDiscoveredServices:discoveredServices];

    if (deviceHasAllRequiredServices) {
        return device;
    }

    // try to iterate through all the child devices
    NSArray *subDevices = [device valueForKeyPath:@"deviceList.device"];
    if (subDevices) {
        if (![subDevices isKindOfClass:[NSArray class]]) {
            subDevices = [NSArray arrayWithObject:subDevices];
        }

        for (NSDictionary *subDevice in subDevices) {
            NSDictionary *foundDevice = [self device:subDevice
                          containingRequiredServices:requiredServices];
            if (foundDevice) {
                return foundDevice;
            }
        }
    }

    return nil;
}

/// Returns a device description that contains services for the given filter. It
/// may be the root device or any of the subdevices. If no device matches,
/// returns @c nil.
- (NSDictionary *)device:(NSDictionary *)device containingServicesWithFilter:(NSString *)filter {
    NSArray *requiredServices = [self requiredServicesForFilter:filter];
    return [self device:device
containingRequiredServices:requiredServices];
}

- (NSArray *) serviceIdsForFilter:(NSString *)filter
{
    __block NSMutableArray *serviceIds = [NSMutableArray new];
    
    [_serviceFilters enumerateObjectsUsingBlock:^(NSDictionary *serviceFilter, NSUInteger idx, BOOL *stop) {
        NSString *ssdpFilter = [[serviceFilter objectForKey:@"ssdp"] objectForKey:@"filter"];
        
        if ([ssdpFilter isEqualToString:filter])
            [serviceIds addObject:[serviceFilter objectForKey:@"serviceId"]];
    }];
    
    return [NSArray arrayWithArray:serviceIds];
}

- (NSArray *) serviceListForDevice:(id)device
{
    NSMutableArray *list = [NSMutableArray new];

    id serviceList = device[@"serviceList"][@"service"];

    if ([serviceList isKindOfClass:[NSArray class]])
        [list addObjectsFromArray:serviceList];
    else if ([serviceList isKindOfClass:[NSDictionary class]])
        [list addObject:serviceList];

    NSArray *devices = nil;
    id devicesObject = device[@"deviceList"][@"device"];
    if ([devicesObject isKindOfClass:[NSArray class]]) {
        devices = devicesObject;
    } else if ([devicesObject isKindOfClass:[NSDictionary class]]) {
        devices = [NSArray arrayWithObject:devicesObject];
    }

    if (devices)
    {
        [devices enumerateObjectsUsingBlock:^(id deviceInfo, NSUInteger idx, BOOL *stop) {
            id services = deviceInfo[@"serviceList"][@"service"];

            if ([services isKindOfClass:[NSArray class]])
                [list addObjectsFromArray:services];
            else if ([services isKindOfClass:[NSDictionary class]])
                [list addObject:services];
        }];
    }

    return [NSArray arrayWithArray:list];
}

- (void) performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay
{
    [self performSelector:@selector(performBlock:) withObject:block afterDelay:delay];
}

- (void) performBlock:(void (^)())block
{
    if (block)
        block();
}

- (NSString *) userAgentForToken:(NSString *)token
{
    if (!token)
        token = @"UPnP/1.1";

    return [NSString stringWithFormat:
            @"%@/%@ %@ ConnectSDK/%@",
            [UIDevice currentDevice].systemName,
            [UIDevice currentDevice].systemVersion,
            token,
            CONNECT_SDK_VERSION];
}

@end
