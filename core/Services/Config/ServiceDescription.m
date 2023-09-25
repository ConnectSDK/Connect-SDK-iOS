//
//  ServiceDescription.m
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

#import "ServiceDescription.h"
#import "CommonMacros.h"

@implementation ServiceDescription

- (instancetype)initWithAddress:(NSString *)address UUID:(NSString*)UUID
{
    self = [super init];
    
    if (self)
    {
        self.address = address;
        self.UUID = UUID;
        self.port = 0;
        self.lastDetection = [[NSDate date] timeIntervalSince1970];
    }
    
    return self;
}

+ (instancetype)descriptionWithAddress:(NSString *)address UUID:(NSString*)UUID
{
    return [[ServiceDescription alloc] initWithAddress:address UUID:UUID];
}

#pragma mark - JSONObjectCoding methods

- (instancetype) initWithJSONObject:(NSDictionary *)dict
{
    self = [super init];

    if (self)
    {
        self.serviceId = dict[@"serviceId"];
        self.address = dict[@"address"];
        self.port = [dict[@"port"] intValue];
        self.UUID = dict[@"UUID"];
        self.type = dict[@"serviceId"];
        self.version = dict[@"version"];
        self.friendlyName = dict[@"friendlyName"];
        self.manufacturer = dict[@"manufacturer"];
        self.modelName = dict[@"modelName"];
        self.modelDescription = dict[@"modelDescription"];
        self.modelNumber = dict[@"modelNumber"];

        NSString *commandPath = dict[@"commandURL"];

        if (commandPath)
            self.commandURL = [NSURL URLWithString:commandPath];
    }

    return self;
}

- (NSDictionary *) toJSONObject
{
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    if (self.serviceId) dictionary[@"serviceId"] = self.serviceId;
    if (self.address) dictionary[@"address"] = self.address;
    if (self.port) dictionary[@"port"] = @(self.port);
    if (self.UUID) dictionary[@"UUID"] = self.UUID;
    if (self.type) dictionary[@"type"] = self.type;
    if (self.version) dictionary[@"version"] = self.version;
    if (self.friendlyName) dictionary[@"friendlyName"] = self.friendlyName;
    if (self.manufacturer) dictionary[@"manufacturer"] = self.manufacturer;
    if (self.modelName) dictionary[@"modelName"] = self.modelName;
    if (self.modelDescription) dictionary[@"modelDescription"] = self.modelDescription;
    if (self.modelNumber) dictionary[@"modelNumber"] = self.modelNumber;
    if (self.commandURL) dictionary[@"commandURL"] = self.commandURL.absoluteString;

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

#pragma mark - NSCopying methods

- (id) copy
{
    ServiceDescription *serviceDescription = [[ServiceDescription alloc] initWithAddress:[self.address copy] UUID:[self.UUID copy]];
    serviceDescription.serviceId = [self.serviceId copy];
    serviceDescription.port = self.port;
    serviceDescription.type = [self.type copy];
    serviceDescription.version = [self.version copy];
    serviceDescription.friendlyName = [self.friendlyName copy];
    serviceDescription.manufacturer = [self.manufacturer copy];
    serviceDescription.modelName = [self.modelName copy];
    serviceDescription.modelDescription = [self.modelDescription copy];
    serviceDescription.modelNumber = [self.modelNumber copy];
    serviceDescription.commandURL = [self.commandURL copy];
    serviceDescription.locationResponseHeaders = [self.locationResponseHeaders copy];
    serviceDescription.locationXML = [self.locationXML copy];
    serviceDescription.serviceList = [self.serviceList copy];

    return serviceDescription;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [self copy];
}

#pragma mark - Equality methods

- (BOOL)isEqualToServiceDescription:(ServiceDescription *)service
{
    if (!service) {
        return NO;
    }

    NSArray *stringProperties = @[STRING_PROPERTY(address),
                                  STRING_PROPERTY(serviceId),
                                  STRING_PROPERTY(UUID),
                                  STRING_PROPERTY(type),
                                  STRING_PROPERTY(version),
                                  STRING_PROPERTY(friendlyName),
                                  STRING_PROPERTY(manufacturer),
                                  STRING_PROPERTY(modelName),
                                  STRING_PROPERTY(modelDescription),
                                  STRING_PROPERTY(modelNumber),
                                  STRING_PROPERTY(locationXML)];
    for (NSString *propName in stringProperties) {
        NSString *selfProp = [self valueForKey:propName];
        NSString *otherProp = [service valueForKey:propName];
        const BOOL haveSameProperty = (!selfProp && !otherProp) || [selfProp isEqualToString:otherProp];
        if (!haveSameProperty) {
            return NO;
        }
    };

    const BOOL haveSamePort = (self.port == service.port);
    const BOOL haveSameCommandURL = (!self.commandURL && !service.commandURL) || [self.commandURL isEqual:service.commandURL];
    const BOOL haveSameServiceList = (!self.serviceList && !service.serviceList) || [self.serviceList isEqualToArray:service.serviceList];
    const BOOL haveSameHeaders = (!self.locationResponseHeaders && !service.locationResponseHeaders) || [self.locationResponseHeaders isEqualToDictionary:service.locationResponseHeaders];
    const BOOL haveSameDevices = ((!self.device && !service.device) ||
                                  [self.device isEqual:service.device]);

    // NB: lastDetection isn't compared here
    return (haveSamePort && haveSameCommandURL && haveSameServiceList &&
            haveSameHeaders && haveSameDevices);
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[ServiceDescription class]]) {
        return NO;
    }

    return [self isEqualToServiceDescription:object];
}

- (NSUInteger)hash
{
    NSArray *properties = @[STRING_PROPERTY(address),
                            STRING_PROPERTY(serviceId), STRING_PROPERTY(UUID),
                            STRING_PROPERTY(type), STRING_PROPERTY(version),
                            STRING_PROPERTY(friendlyName),
                            STRING_PROPERTY(manufacturer),
                            STRING_PROPERTY(modelName),
                            STRING_PROPERTY(modelDescription),
                            STRING_PROPERTY(modelNumber),
                            STRING_PROPERTY(commandURL),
                            STRING_PROPERTY(locationXML),
                            STRING_PROPERTY(serviceList),
                            STRING_PROPERTY(locationResponseHeaders),
                            STRING_PROPERTY(device)];
    NSUInteger hash = 0;
    for (NSString *propName in properties) {
        id prop = [self valueForKey:propName];
        hash ^= [prop hash];
    }

    hash ^= self.port;
    // NB: lastDetection isn't used here

    return hash;
}

@end
