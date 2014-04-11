//
// Created by Jeremy White on 1/2/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
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
