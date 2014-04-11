//
// Created by Jeremy White on 1/3/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "AppInfo.h"

@implementation AppInfo

+ (AppInfo *) appInfoForId:(NSString *)appId
{
    AppInfo *appInfo = [AppInfo new];
    appInfo.id = appId;

    return appInfo;
}

- (BOOL)isEqual:(AppInfo *)appInfo
{
    return [self.id isEqualToString:appInfo.id];
}

@end
