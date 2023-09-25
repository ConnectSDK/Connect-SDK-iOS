//
//  MediaLaunchObject.h
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 1/19/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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
#import "MediaControl.h"
#import "PlayListControl.h"
#import "LaunchSession.h"

/*! MediaLaunchObject is a container object which holds LaunchSession object,MediaControl object/or and PlayListControl object*/
@interface MediaLaunchObject : NSObject

/*! MediaControl object of Media player*/
@property (nonatomic, strong) id<MediaControl> mediaControl;

/*! PlayList Control Object of Media player*/
@property (nonatomic, strong) id<PlayListControl> playListControl;

/*! Launch Session object of Media player*/
@property (nonatomic, strong) LaunchSession *session;


/*!
 * Creates an instance of MediaLaunchObject with given property values.
 *
 * @param launchSession LaunchSession to allow closing this media player
 * @param mediaControl MediaControl object used to control playback
 * @param playListControl PlayListControl object used to control playlist
 */
- (instancetype) initWithLaunchSession:(LaunchSession *)session andMediaControl:(id<MediaControl>)mediaControl;
- (instancetype) initWithLaunchSession:(LaunchSession *)session andMediaControl:(id<MediaControl>)mediaControl andPlayListControl:(id<PlayListControl>)playListControl;

@end
