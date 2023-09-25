//
//  LCStreamer.h
//  GStreamerForLGCast
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

#import <Foundation/Foundation.h>

typedef enum {
    Video = 0,
    Audio,
    AV
} LCStreamerMediaType;

extern NSString* const LCStreamerAudioSourceBinName;
extern NSString* const LCStreamerAudioRtpBinName;
extern NSString* const LCStreamerAudioSrtpBinName;

extern NSString* const LCStreamerVideoSourceBinName;
extern NSString* const LCStreamerVideoRtpBinName;
extern NSString* const LCStreamerVideoSrtpBinName;

@protocol LCStreamerDelegate <NSObject>
- (void)gstreamerDidInitialize;
- (void)gstreamerDidSendMessage:(NSString *)message;
@end

@interface LCStreamer: NSObject

@property (nonatomic, weak) id<LCStreamerDelegate> delegate;

- (id)init:(id)delegate;
- (void)setDebugLevel:(int)level;
- (BOOL)setStreamerInfo:(NSDictionary *)info;
- (void)start;
- (BOOL)sendMediaData:(int32_t)mediaType pts:(UInt64)pts data:(NSData *)data;
- (void)stop;

@end
