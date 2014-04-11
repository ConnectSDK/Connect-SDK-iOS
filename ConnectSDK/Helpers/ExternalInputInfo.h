//
// Created by Jeremy White on 1/19/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ExternalInputInfo : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL connected;
@property (nonatomic, strong) NSURL *iconURL;

@property (nonatomic, strong) id rawData;

- (BOOL)isEqual:(ExternalInputInfo *)externalInputInfo;

@end
