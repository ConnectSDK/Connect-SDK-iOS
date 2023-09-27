//
//  ServiceDescription.h
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

#import <Foundation/Foundation.h>
#import "JSONObjectCoding.h"

@interface ServiceDescription : NSObject <JSONObjectCoding, NSCopying>

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *serviceId;
@property (nonatomic) NSUInteger port;
@property (nonatomic, strong) NSString *UUID;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *friendlyName;
@property (nonatomic, strong) NSString *manufacturer;
@property (nonatomic, strong) NSString *modelName;
@property (nonatomic, strong) NSString *modelDescription;
@property (nonatomic, strong) NSString *modelNumber;
@property (nonatomic, strong) NSURL *commandURL;
@property (nonatomic, strong) NSString *locationXML;
@property (nonatomic, strong) NSArray *serviceList;
@property (nonatomic, strong) NSDictionary *locationResponseHeaders;
@property (nonatomic) double lastDetection;
/**
 * @brief A device object set by a discovery provider when a service requires it (that is, it is the
 * only way to control the remote device).
 *
 * For example, @c CastService requires a @c GCKDevice object retrieved during discovery in
 * <tt>CastDiscoveryProvider</tt>. On the other hand, @c DLNAService doesn't require any specific
 * object, because it works via HTTP using other properties.
 * @note The service is responsible for checking that the property is of the expected type.
 */
@property (nonatomic, strong) id device;

- (instancetype)initWithAddress:(NSString *)address UUID:(NSString*)UUID;
+ (instancetype)descriptionWithAddress:(NSString *)address UUID:(NSString*)UUID;

- (BOOL)isEqualToServiceDescription:(ServiceDescription *)service;

@end
