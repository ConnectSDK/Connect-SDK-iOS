//
//  DLNAService_Private.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/13/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
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

#import "DLNAService.h"

extern NSString *const kDataFieldName;

@class DeviceServiceReachability;
@class DLNAHTTPServer;

@interface DLNAService ()

@property (nonatomic, strong) id<ServiceCommandDelegate> serviceCommandDelegate;

@property (nonatomic, strong) NSURL *avTransportControlURL;
@property (nonatomic, strong) NSURL *avTransportEventURL;
@property (nonatomic, strong) NSURL *renderingControlControlURL;
@property (nonatomic, strong) NSURL *renderingControlEventURL;

- (NSURL*)serviceURLForPath:(NSString *)path;
/// Parses and returns a metadata dictionary from the @c metaDataXML string.
- (NSDictionary *)parseMetadataDictionaryFromXMLString:(NSString *)metadataXML;

/// Creates a new @c DLNAHTTPServer instance.
- (DLNAHTTPServer *)createDLNAHTTPServer;
/// Creates a new @c DeviceServiceReachability instance with the given target URL.
- (DeviceServiceReachability *)createDeviceServiceReachabilityWithTargetURL:(NSURL *)url;

@end
