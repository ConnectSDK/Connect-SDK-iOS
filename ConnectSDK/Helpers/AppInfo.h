//
// Created by Jeremy White on 1/3/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 * Normalized reference object for information about a DeviceService's app. This object will, in most cases, be used to launch apps.
 *
 * In some cases, all that is needed to launch an app is the app id. For these cases, a static constructor method has been provided.
 */
@interface AppInfo : NSObject

/*!
 * ID of the app on the first screen device. Format is different depending on the platform. (ex. youtube.leanback.v4, 0000001134, netflix, etc).
 */
@property (nonatomic, strong) NSString *id;

/*! User-friendly name of the app (ex. YouTube, Browser, Netflix, etc). */
@property (nonatomic, strong) NSString *name;

/*! Raw data from the first screen device about the app. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

/*!
 * Compares two AppInfo objects.
 *
 * @param appInfo AppInfo object to compare.
 *
 * @return YES if both AppInfo id values are equal
 */
- (BOOL)isEqual:(AppInfo *)appInfo;

/*!
 * Static constructor method.
 *
 * @param appId ID of the app on the first screen device
 */
+ (AppInfo *) appInfoForId:(NSString *)appId;

@end
