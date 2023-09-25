//
//  MirroringSinkCapability.m
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

#import "MirroringSinkCapability.h"

@interface MirroringSinkCapability()

@property NSString *deviceType;
@property NSString *deviceVersion;
@property NSString *devicePlatform;
@property NSString *deviceSoC;

@property NSString *videoCodec;
@property NSString *audioCodec;

@property NSInteger videoPortraitMaxWidth;
@property NSInteger videoPortraitMaxHeight;
@property NSInteger videoLandscapeMaxWidth;
@property NSInteger videoLandscapeMaxHeight;

@property NSString *supportedOrientation;

@end

@implementation MirroringSinkCapability

#define DEFAULT_SCREEN_WIDTH 1920
#define DEFAULT_SCREEN_HEIGHT 1080

-(id)initWithInfo:(NSDictionary*)info {
    self = [super init];
    
    _ipAddress = [info objectForKey:@"ipAddress"];
    if (_ipAddress == nil && _ipAddress.length == 0 ) {
        _ipAddress = @"127.0.0.1";
    }
    _keepAliveTimeout = [[info objectForKey:@"keepAliveTimeout"] doubleValue];
    if (_keepAliveTimeout == 0) {
        _keepAliveTimeout = 60;
    }
    _publicKey = [info objectForKey:@"publicKey"];
    
    NSDictionary* deviceInfoObj = [info objectForKey:@"deviceInfo"] ;
    if (deviceInfoObj != nil && deviceInfoObj.count > 0) {
        _deviceType = [deviceInfoObj objectForKey:@"type"];
        _deviceVersion = [deviceInfoObj objectForKey:@"version"];
        _devicePlatform = [deviceInfoObj objectForKey:@"platform"];
        _deviceSoC = [deviceInfoObj objectForKey:@"SoC"];
    }
    
    NSDictionary* mirroringObj = [info objectForKey:@"mirroring"];
    if (mirroringObj != nil && mirroringObj.count > 0) {
        NSDictionary* videoObj = [mirroringObj objectForKey:@"video"];
        if (videoObj != nil && videoObj.count > 0) {
            _videoCodec = [videoObj objectForKey:@"codec"];
            _videoUdpPort = [[videoObj objectForKey:@"udpPort"] intValue];
            
            // V2 properties
            NSDictionary* videoPortraitSize = [videoObj objectForKey:@"portrait"];
            if (videoPortraitSize != nil && videoPortraitSize.count > 0) {
                _videoPortraitMaxWidth = [[videoPortraitSize objectForKey:@"maxWidth"] intValue];
                _videoPortraitMaxHeight = [[videoPortraitSize objectForKey:@"maxHeight"] intValue];
            } else {
                _videoPortraitMaxWidth = DEFAULT_SCREEN_HEIGHT;
                _videoPortraitMaxHeight = DEFAULT_SCREEN_WIDTH;
            }
            
            // V2 properties
            NSDictionary* videoLandscapeSize = [videoObj objectForKey:@"landscape"];
            if (videoLandscapeSize != nil && videoLandscapeSize.count > 0) {
                _videoLandscapeMaxWidth = [[videoLandscapeSize objectForKey:@"maxWidth"] intValue];
                _videoLandscapeMaxHeight = [[videoLandscapeSize objectForKey:@"maxHeight"] intValue];
            } else { // V1 properties
                // TODO
                _videoLandscapeMaxWidth = DEFAULT_SCREEN_WIDTH;
                _videoLandscapeMaxHeight = DEFAULT_SCREEN_HEIGHT;
            }
        }
        
        NSDictionary* audioObj = [mirroringObj objectForKey:@"audio"];
        if (audioObj != nil && audioObj.count > 0) {
            _audioCodec = [audioObj objectForKey:@"codec"];
            _audioUdpPort = [[audioObj objectForKey:@"udpPort"] intValue];
        }
        
        NSDictionary* supportedFeatures = [mirroringObj objectForKey:@"supportedFeatures"];
        if (supportedFeatures != nil && supportedFeatures.count > 0) {
            _supportedOrientation = [supportedFeatures objectForKey:@"screenOrientation"];
            if (_supportedOrientation == nil) {
                _supportedOrientation = @"landscape";
            }
        }
        
        _displayOrientation = [mirroringObj objectForKey:@"displayOrientation"];
        if (_displayOrientation == nil) {
            _displayOrientation = @"landscape";
        }
    }
    
    return self;
}

@end
