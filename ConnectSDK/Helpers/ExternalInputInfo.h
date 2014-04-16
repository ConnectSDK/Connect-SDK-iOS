//
//  ExternalInputInfo.h
//  Connect SDK
//
//  Created by Jeremy White on 1/19/14.
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


/*!
 * Normalized reference object for information about a DeviceService's external inputs. This object is required to set a DeviceService's external input.
 */
@interface ExternalInputInfo : NSObject

/*! ID of the external input on the first screen device. */
@property (nonatomic, strong) NSString *id;

/*! User-friendly name of the external input (ex. AV, HDMI1, etc). */
@property (nonatomic, strong) NSString *name;

/*! Whether the DeviceService is currently connected to this external input. */
@property (nonatomic) BOOL connected;

/*! URL to an icon representing this external input. */
@property (nonatomic, strong) NSURL *iconURL;

/*! Raw data from the first screen device about the external input. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

/*!
 * Compares two ExternalInputInfo objects.
 *
 * @param externalInputInfo ExternalInputInfo object to compare.
 *
 * @return YES if both ExternalInputInfo id & name values are equal
 */
- (BOOL)isEqual:(ExternalInputInfo *)externalInputInfo;

@end
