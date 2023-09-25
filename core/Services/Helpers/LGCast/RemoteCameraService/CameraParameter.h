//
//  CameraParameter.h
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

#ifndef CameraParameter_h
#define CameraParameter_h

#import <Foundation/Foundation.h>

@interface CameraParameter : NSObject

@property NSInteger width;
@property NSInteger height;
@property NSInteger brightness;
@property NSInteger whiteBalance;
@property BOOL autoWhiteBalance;
@property NSInteger facing;
@property BOOL audio;
@property NSInteger rotation;

- (NSDictionary *)toNSDictionary;
- (NSDictionary *)toNSDictionaryResolutionResult:(BOOL)result width:(int)width height:(int)height;
- (NSDictionary *)toNSDictionaryBritnessResult:(BOOL)result brightness:(int)brightness;
- (NSDictionary *)toNSDictionaryWhiteBalanceResult:(BOOL)result whiteBalance:(int)whiteBalance;
- (NSDictionary *)toNSDictionaryAutoWhiteBalanceResult:(BOOL)result autoWhiteBalance:(BOOL)autoWhiteBalance;
- (NSDictionary *)toNSDictionaryFacing:(int)facing;
- (NSDictionary *)toNSDictionaryFacingResult:(BOOL)result facing:(int)facing;
- (NSDictionary *)toNSDictionaryAudio:(BOOL)audio;
- (NSDictionary *)toNSDictionaryAudioResult:(BOOL)result audio:(BOOL)audio;

@end

#endif /* CameraParameter_h */
