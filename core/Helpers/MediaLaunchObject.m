//
//  MediaLaunchObject.m
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

#import "MediaLaunchObject.h"

@implementation MediaLaunchObject

- (instancetype) initWithLaunchSession:(LaunchSession *)session andMediaControl:(id<MediaControl>)mediaControl
{
    return [self initWithLaunchSession:session andMediaControl:mediaControl andPlayListControl:nil];
}

- (instancetype) initWithLaunchSession:(LaunchSession *)session andMediaControl:(id<MediaControl>)mediaControl andPlayListControl:(id<PlayListControl>)playListControl
{
    self = [super init];
    
    if (self)
    {
        self.session = session;
        self.mediaControl = mediaControl;
        self.playListControl = playListControl;
    }
    
    return self;
}

@end
