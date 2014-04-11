//
// Created by Jeremy White on 1/2/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ChannelInfo : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *number;
@property (nonatomic) int majorNumber;
@property (nonatomic) int minorNumber;

@property (nonatomic, strong) id rawData;

- (BOOL)isEqual:(ChannelInfo *)channelInfo;

@end
