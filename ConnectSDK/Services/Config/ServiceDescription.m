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

@end
