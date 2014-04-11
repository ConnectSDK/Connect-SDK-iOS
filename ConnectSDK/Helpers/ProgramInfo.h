//
// Created by Jeremy White on 1/19/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChannelInfo;


/*! Normalized reference object for information about a TVs program. */
@interface ProgramInfo : NSObject

/*! ID of the program on the first screen device. Format is different depending on the platform. */
@property (nonatomic, strong) NSString *id;

/*! User-friendly name of the program (ex. Sesame Street, Cosmos, Game of Thrones, etc). */
@property (nonatomic, strong) NSString *name;

/*! Reference to the ChannelInfo object that this program is associated with */
@property (nonatomic, strong) ChannelInfo *channelInfo;

/*! Raw data from the first screen device about the program. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

/*!
 * Compares two ProgramInfo objects.
 *
 * @param programInfo ProgramInfo object to compare.
 *
 * @return YES if both ProgramInfo id & name values are equal
 */
- (BOOL)isEqual:(ProgramInfo *)programInfo;

@end
