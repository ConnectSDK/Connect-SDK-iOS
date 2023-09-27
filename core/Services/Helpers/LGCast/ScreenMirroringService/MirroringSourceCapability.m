//
//  MirroringSourceCapability.m
//  LGCast
//
//  Copyright (c) 2022 LG Electronics. All rights reserved.
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

#import "MirroringSourceCapability.h"

@interface MirroringSourceCapability()
    @property NSArray<LGCastSecurityKey *> *masterKeys;
@end

@implementation MirroringSourceCapability
- (void)setSecurityKeys:(NSArray<LGCastSecurityKey *> *)keys {
    _masterKeys = keys;
}

- (NSDictionary *)toNSDictionary {
    NSDictionary* videoSpec = [NSDictionary dictionaryWithObjectsAndKeys:
                            _videoCodec, @"codec",
                            [NSNumber numberWithLong:_videoClockRate], @"clockRate",
                            [NSNumber numberWithLong:_videoFramerate], @"framerate",
                            [NSNumber numberWithLong:_videoBitrate], @"bitrate",
                            [NSNumber numberWithLong:_videoWidth], @"width",
                            [NSNumber numberWithLong:_videoHeight], @"height",
                            [NSNumber numberWithLong:_videoActiveWidth], @"activeWidth",
                            [NSNumber numberWithLong:_videoActiveHeight], @"activeHeight",
                            _videoOrientation, @"orientation", nil];
    
    NSDictionary* audioSpec = [NSDictionary dictionaryWithObjectsAndKeys:
                            _audioCodec, @"codec",
                            [NSNumber numberWithLong:_audioClockRate], @"clockRate",
                            [NSNumber numberWithLong:_audioFrequency], @"frequency",
                            _audioStreamMuxConfig, @"streamMuxConfig",
                            [NSNumber numberWithLong:_audioChannels], @"channels", nil];

   
    NSMutableArray<NSDictionary *> *cryptoSpec = [[NSMutableArray alloc] init];

    for (LGCastSecurityKey *key in _masterKeys) {
        [cryptoSpec addObject:@{
            @"mki": key.mki,
            @"key": key.masterKey
        }];
    }
    
    NSDictionary* supportedFeatures = [NSDictionary dictionaryWithObjectsAndKeys:
                            _screenOrientation, @"screenOrientation", nil];
    
    
    return @{
        @"video": videoSpec,
        @"audio": audioSpec,
        @"crypto": cryptoSpec,
        @"uibcEnabled": @NO,
        @"supportedFeatures": supportedFeatures
    };
}

- (NSDictionary *)toNSDictionaryVideoSize {
    NSDictionary* videoSpec = [NSDictionary dictionaryWithObjectsAndKeys:
                            _videoOrientation, @"orientation",
                            [NSNumber numberWithLong:_videoWidth], @"width",
                            [NSNumber numberWithLong:_videoHeight], @"height",
                            [NSNumber numberWithLong:_videoActiveWidth], @"activeWidth",
                            [NSNumber numberWithLong:_videoActiveHeight], @"activeHeight", nil];
    
    return @{@"video": videoSpec};
}

@end
