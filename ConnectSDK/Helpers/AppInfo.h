//
// Created by Jeremy White on 1/3/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AppInfo : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) id rawData;

- (BOOL)isEqual:(AppInfo *)appInfo;

+ (AppInfo *) appInfoForId:(NSString *)appId;

@end
