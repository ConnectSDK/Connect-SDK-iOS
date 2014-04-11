//
// Created by Jeremy White on 12/16/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Capability.h"
#import "Launcher.h"
#import "MediaControl.h"

#define kMediaPlayerAny @"MediaPlayer.Any"

#define kMediaPlayerDisplayImage @"MediaPlayer.Display.Image"
#define kMediaPlayerDisplayVideo @"MediaPlayer.Display.Video"
#define kMediaPlayerDisplayAudio @"MediaPlayer.Display.Audio"
#define kMediaPlayerClose @"MediaPlayer.Close"
#define kMediaPlayerMetaDataTitle @"MediaPlayer.MetaData.Title"
#define kMediaPlayerMetaDataDescription @"MediaPlayer.MetaData.Description"
#define kMediaPlayerMetaDataThumbnail @"MediaPlayer.MetaData.Thumbnail"
#define kMediaPlayerMetaDataMimeType @"MediaPlayer.MetaData.MimeType"

#define kMediaPlayerCapabilities @[\
    kMediaPlayerDisplayImage,\
    kMediaPlayerDisplayVideo,\
    kMediaPlayerDisplayAudio,\
    kMediaPlayerClose,\
    kMediaPlayerMetaDataTitle,\
    kMediaPlayerMetaDataDescription,\
    kMediaPlayerMetaDataThumbnail,\
    kMediaPlayerMetaDataMimeType\
]

@protocol MediaPlayer <NSObject>

/**
 * @param launchSession LaunchSession to allow closing this media player
 * @param mediaControl MediaControl instance used to control playback
 */
typedef void (^MediaPlayerDisplaySuccessBlock)(LaunchSession *launchSession, id<MediaControl> mediaControl);

- (id<MediaPlayer>) mediaPlayer;
- (CapabilityPriorityLevel) mediaPlayerPriority;

- (void) displayImage:(NSURL *)imageURL
             iconURL:(NSURL *)iconURL
               title:(NSString *)title
         description:(NSString *)description
            mimeType:(NSString *)mimeType
             success:(MediaPlayerDisplaySuccessBlock)success
             failure:(FailureBlock)failure;

- (void) playMedia:(NSURL *)mediaURL
           iconURL:(NSURL *)iconURL
             title:(NSString *)title
       description:(NSString *)description
          mimeType:(NSString *)mimeType
        shouldLoop:(BOOL)shouldLoop
           success:(MediaPlayerDisplaySuccessBlock)success
           failure:(FailureBlock)failure;

- (void) closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
