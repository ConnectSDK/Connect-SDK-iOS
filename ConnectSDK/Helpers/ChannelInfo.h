//
//  ChannelInfo.h
//  Connect SDK
//
//  Created by Jeremy White on 1/2/14.
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
 * Normalized reference object for information about a TVs channels. This object is required to set the channel on a TV.
 */
@interface ChannelInfo : NSObject

/*! TV's unique ID for the channel */
@property (nonatomic, strong) NSString *id;

/*! User-friendly name of the channel */
@property (nonatomic, strong) NSString *name;

/*! TV channel's number (likely to be a combination of the major & minor numbers) */
@property (nonatomic, strong) NSString *number;

/*! TV channel's major number */
@property (nonatomic) int majorNumber;

/*! TV channel's minor number */
@property (nonatomic) int minorNumber;

/*! Raw data from the first screen device about the channel. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

/*!
 * Compares two ChannelInfo objects.
 *
 * @param channelInfo ChannelInfo object to compare.
 *
 * @return YES if both ChannelInfo number & name values are equal
 */
- (BOOL)isEqual:(ChannelInfo *)channelInfo;

@end
