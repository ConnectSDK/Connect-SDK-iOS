//
//  CameraParameter.m
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

#import "CameraParameter.h"
#import "RemoteCameraService.h"

@implementation CameraParameter

- (NSDictionary *)toNSDictionary {
    return @{
        kRCKeyWidth : [NSNumber numberWithLong:_width],
        kRCKeyHeight : [NSNumber numberWithLong:_height],
        kRCKeyBrightness : [NSNumber numberWithLong:_brightness],
        kRCKeyWhiteBalance : [NSNumber numberWithLong:_whiteBalance],
        kRCKeyAutoWhiteBalance : [NSNumber numberWithBool:_autoWhiteBalance],
        kRCKeyFacing : [NSNumber numberWithLong:_facing],
        kRCKeyAudio : [NSNumber numberWithBool:_audio],
        kRCKeyRotation : [NSNumber numberWithLong:_rotation]
    };
}

- (NSDictionary *)toNSDictionaryResolutionResult:(BOOL)result width:(int)width height:(int)height {
    if (result) {
        _width = width;
        _height = height;
    }
    
    return @{
        kRCKeyResult : [NSNumber numberWithBool:result],
        kRCKeyWidth : [NSNumber numberWithLong:_width],
        kRCKeyHeight : [NSNumber numberWithLong:_height]
    };
}

- (NSDictionary *)toNSDictionaryBritnessResult:(BOOL)result brightness:(int)brightness {
    if (result) {
        _brightness = brightness;
    }
    
    return @{
        kRCKeyResult : [NSNumber numberWithBool:result],
        kRCKeyBrightness : [NSNumber numberWithLong:_brightness]
    };
}

- (NSDictionary *)toNSDictionaryWhiteBalanceResult:(BOOL)result whiteBalance:(int)whiteBalance {
    if (result) {
        _whiteBalance = whiteBalance;
    }
    
    return @{
        kRCKeyResult : [NSNumber numberWithBool:result],
        kRCKeyWhiteBalance : [NSNumber numberWithLong:_whiteBalance]
    };
}

- (NSDictionary *)toNSDictionaryAutoWhiteBalanceResult:(BOOL)result autoWhiteBalance:(BOOL)autoWhiteBalance {
    if (result) {
        _autoWhiteBalance = autoWhiteBalance;
    }
    
    return @{
        kRCKeyResult : [NSNumber numberWithBool:result],
        kRCKeyAutoWhiteBalance : [NSNumber numberWithBool:_autoWhiteBalance]
    };
}

- (NSDictionary *)toNSDictionaryFacing:(int)facing {
    _facing = facing;
    
    return @{
        kRCKeyFacing : [NSNumber numberWithLong:_facing]
    };
}

- (NSDictionary *)toNSDictionaryFacingResult:(BOOL)result facing:(int)facing {
    if (result) {
        _facing = facing;
    }
    
    return @{
        kRCKeyResult : [NSNumber numberWithBool:result],
        kRCKeyFacing : [NSNumber numberWithLong:_facing]
    };
}

- (NSDictionary *)toNSDictionaryAudio:(BOOL)audio {
    _audio = audio;
    
    return @{
        kRCKeyAudio : [NSNumber numberWithBool:audio]
    };
}

- (NSDictionary *)toNSDictionaryAudioResult:(BOOL)result audio:(BOOL)audio {
    if (result) {
        _audio = audio;
    }
    
    return @{
        kRCKeyResult : [NSNumber numberWithBool:result],
        kRCKeyAudio : [NSNumber numberWithBool:audio]
    };
}

@end
