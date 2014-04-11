//
// Created by Jeremy White on 1/19/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChannelInfo;


@interface ProgramInfo : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) ChannelInfo *channelInfo;

@property (nonatomic, strong) id rawData;

- (BOOL)isEqual:(ProgramInfo *)programInfo;

@end
