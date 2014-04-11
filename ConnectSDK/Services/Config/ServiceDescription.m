//
//  ServiceDescription.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ServiceDescription.h"

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

#pragma mark - NSCoding methods

- (id) initWithCoder:(NSCoder *)aDecoder
{
    NSString *address = [aDecoder decodeObjectForKey:@"address"];
    NSString *UUID = [aDecoder decodeObjectForKey:@"UUID"];

    self = [self initWithAddress:address UUID:UUID];

    if (self)
    {
        self.serviceId = [aDecoder decodeObjectForKey:@"serviceId"];
        self.port = [aDecoder decodeIntegerForKey:@"port"];
        self.type = [aDecoder decodeObjectForKey:@"type"];
        self.version = [aDecoder decodeObjectForKey:@"version"];
        self.friendlyName = [aDecoder decodeObjectForKey:@"friendlyName"];
        self.manufacturer = [aDecoder decodeObjectForKey:@"manufacturer"];
        self.modelName = [aDecoder decodeObjectForKey:@"modelName"];
        self.modelDescription = [aDecoder decodeObjectForKey:@"modelDescription"];
        self.modelNumber = [aDecoder decodeObjectForKey:@"modelNumber"];
        self.commandURL = [aDecoder decodeObjectForKey:@"commandURL"];
        self.locationXML = [aDecoder decodeObjectForKey:@"locationXML"];
        self.locationResponseHeaders = [aDecoder decodeObjectForKey:@"locationResponseHeaders"];
        self.lastDetection = [aDecoder decodeDoubleForKey:@"lastDetection"];
    }

    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.address forKey:@"address"];
    [aCoder encodeObject:self.serviceId forKey:@"serviceId"];
    [aCoder encodeInteger:self.port forKey:@"port"];
    [aCoder encodeObject:self.UUID forKey:@"UUID"];
    [aCoder encodeObject:self.type forKey:@"type"];
    [aCoder encodeObject:self.version forKey:@"version"];
    [aCoder encodeObject:self.friendlyName forKey:@"friendlyName"];
    [aCoder encodeObject:self.manufacturer forKey:@"manufacturer"];
    [aCoder encodeObject:self.modelName forKey:@"modelName"];
    [aCoder encodeObject:self.modelDescription forKey:@"modelDescription"];
    [aCoder encodeObject:self.modelNumber forKey:@"modelNumber"];
    [aCoder encodeObject:self.commandURL forKey:@"commandURL"];
    [aCoder encodeObject:self.locationXML forKey:@"locationXML"];
    [aCoder encodeObject:self.locationResponseHeaders forKey:@"locationResponseHeaders"];
    [aCoder encodeDouble:self.lastDetection forKey:@"lastDetection"];
}

@end
