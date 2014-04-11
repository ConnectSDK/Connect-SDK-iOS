//
// Created by Jeremy White on 1/2/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "ChannelInfo.h"

@implementation ChannelInfo

- (BOOL)isEqual:(ChannelInfo *)channelInfo
{
    return [self.number isEqualToString:channelInfo.number]
            && [self.name isEqualToString:channelInfo.name];
}

@end
