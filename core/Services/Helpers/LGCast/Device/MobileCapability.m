//
//  MobileCapability.m
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

#import "MobileCapability.h"

#import <UIKit/UIKit.h>

@implementation MobileCapability

-(id)init {
    self = [super init];
    _type = @"phone";
    _version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    _platform = @"ios";
    _manufacturer = @"apple";
    _modelName = UIDevice.currentDevice.model;
    _deviceName = UIDevice.currentDevice.name;

    return self;
}

- (NSDictionary*)toNSDictionary {
    NSDictionary* options = [NSDictionary dictionaryWithObjectsAndKeys:
                             _type, @"type",
                             _version, @"version",
                             _platform, @"platform",
                             _manufacturer, @"manufacturer",
                             _modelName, @"modelName",
                             _deviceName, @"deviceName", nil];
    
    return options;
}

@end
