//
//  RemoteCameraService.h
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

#ifndef RemoteCameraService_h
#define RemoteCameraService_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ConnectableDevice.h"
#import "RemoteCameraControl.h"

@protocol RemoteCameraServiceDelegate <NSObject>

- (void)remoteCameraDidPair;
- (void)remoteCameraDidStart:(BOOL)result;
- (void)remoteCameraDidStop:(BOOL)result;
- (void)remoteCameraDidPlay;
- (void)remoteCameraDidChange:(RemoteCameraProperty)property;
- (void)remoteCameraErrorDidOccur:(RemoteCameraError)error;

@end

extern NSString *const kRCKeyCamera;

extern NSString *const kRCKeyResult;

extern NSString *const kRCKeyVideoPort;
extern NSString *const kRCKeyAudioPort;
extern NSString *const kRCKeyWidth;
extern NSString *const kRCKeyHeight;

extern NSString *const kRCKeyFacing;
extern NSString *const kRCKeyAudio;
extern NSString *const kRCKeyBrightness;
extern NSString *const kRCKeyWhiteBalance;
extern NSString *const kRCKeyAutoWhiteBalance;
extern NSString *const kRCKeyRotation;

@interface RemoteCameraService : NSObject

@property (nonatomic, weak) id<RemoteCameraServiceDelegate> delegate;
@property (readonly) BOOL isRunning;

+ (instancetype)sharedInstance;

- (UIView *)startRemoteCamera:(ConnectableDevice *)device settings:(nullable NSDictionary<NSString *, id> *)settings;
- (void)stopRemoteCamera;
- (void)setLensFacing:(int)lensFacing;
- (void)setMicMute:(BOOL)micMute;

@end

#endif /* RemoteCameraService_h */
