//
//  CameraSinkCapability.m
//  LGCast
//
//  Copyright (c) 2022 LG Electronics. All rights reserved.
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

#import "CameraSinkCapability.h"

@implementation CameraSinkCapability

NSString *const kRCKeySinkIpAddress = @"ipAddress";
NSString *const kRCKeySinkKeepAliveTimeout = @"keepAliveTimeout";
NSString *const kRCKeySinkPublicKey = @"publicKey";

NSString *const kRCKeyDeviceInfo = @"deviceInfo";
NSString *const kRCKeyDeviceInfoType = @"type";
NSString *const kRCKeyDeviceInfoVersion = @"version";
NSString *const kRCKeyDeviceInfoPlatform = @"platform";
NSString *const kRCKeyDeviceInfoSoC = @"SoC";

- (id)initWithJSON:(NSDictionary *)jsonObject {
    self = [super init];
    
    _ipAddress = [jsonObject valueForKey:kRCKeySinkIpAddress];
    _keepAliveTimeout = [[jsonObject valueForKey:kRCKeySinkKeepAliveTimeout] doubleValue];
    _publicKey = [jsonObject valueForKey:kRCKeySinkPublicKey];
    
    NSDictionary *deviceInfoObj = [jsonObject valueForKey:kRCKeyDeviceInfo];
    if (deviceInfoObj != NULL) {
        _deviceType = [deviceInfoObj valueForKey:kRCKeyDeviceInfoType];
        _deviceVersion = [deviceInfoObj valueForKey:kRCKeyDeviceInfoVersion];
        _devicePlatform = [deviceInfoObj valueForKey:kRCKeyDeviceInfoPlatform];
        _deviceSoC = [deviceInfoObj valueForKey:kRCKeyDeviceInfoSoC];
    }
    
    return self;
}

@end
