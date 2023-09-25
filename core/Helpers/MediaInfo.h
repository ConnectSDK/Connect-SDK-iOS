//
//  MediaInfo.h
//  Connect SDK
//
//  Created by Jeremy White on 8/14/14.
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
#import "ImageInfo.h"

@class SubtitleInfo;

/*!
 * Normalized reference object for information about a media file to be sent to a device through the MediaPlayer capability. "Media file", in this context, refers to an audio or video resource.
 */
@interface MediaInfo : NSObject

/*! URL source of the media file */
@property (nonatomic, strong) NSURL *url;

/*! Mime-type of the media file */
@property (nonatomic, strong) NSString *mimeType;

/*! Title of the media file (optional) */
@property (nonatomic, strong) NSString *title;

/*! Short description of the media file (optional) */
@property (nonatomic, strong) NSString *description;

/*! Duration of the media file */
@property (nonatomic) NSTimeInterval duration;

/*! Collection of ImageInfo objects to send, as necessary, to the device when launching media through the MediaPlayer capability. */
@property (nonatomic, strong) NSArray *images;

/// Subtitle track for this media instance (optional).
@property (nonatomic, strong) SubtitleInfo *subtitleInfo;


/**
 * Creates an instance of MediaInfo with given property values.
 *
 * @param url URL source of the media file
 * @param mimeType Mime-type of the media file
 */
- (instancetype) initWithURL:(NSURL *)url mimeType:(NSString *)mimeType;

/*!
 * Adds an ImageInfo object to the array of images.
 *
 * @param image ImageInfo object to be added
 */
- (void) addImage:(ImageInfo *)image;

/*!
 * Adds an array of ImageInfo objects to the array of images.
 *
 * @param images Array of ImageInfo objects to be added
 */
- (void) addImages:(NSArray *)images;

@end
