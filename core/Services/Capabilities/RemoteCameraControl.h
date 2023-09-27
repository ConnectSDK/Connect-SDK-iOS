//
//  RemoteCameraControl.h
//  Connect SDK
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

#ifndef RemoteCameraControl_h
#define RemoteCameraControl_h

#import <Foundation/Foundation.h>
#import "Capability.h"

#define kRemoteCameraControlAny @"RemoteCameraControl.Any"

#define kRemoteCameraControlRemoteCamera @"RemoteCameraControl.RemoteCamera"

#define kRemoteCameraControlCapabilities @[\
    kRemoteCameraControlRemoteCamera\
]

#define kRemoteCameraSettingsMicMute @"RemoteCamera.Settings.MicMute"
#define kRemoteCameraSettingsLensFacing @"RemoteCamera.Settings.LensFacing"

typedef NS_ENUM(int, RemoteCameraLensFacing) {
    RemoteCameraLensFacingFront = 0,
    RemoteCameraLensFacingBack = 1
};

typedef NS_ENUM(int, RemoteCameraProperty) {
    RemoteCameraPropertyUnknown,
    RemoteCameraPropertyBrightness,
    RemoteCameraPropertyWhiteBalance,
    RemoteCameraPropertyRotation
};

typedef NS_ENUM(int, RemoteCameraError) {
    RemoteCameraErrorGeneric,
    RemoteCameraErrorConnectionClosed,
    RemoteCameraErrorDeviceShutdown,
    RemoteCameraErrorRendererTerminated
};

@protocol RemoteCameraControlDelegate <NSObject>

- (void)remoteCameraDidPair;
- (void)remoteCameraDidStart:(BOOL)result;
- (void)remoteCameraDidStop:(BOOL)result;
- (void)remoteCameraDidPlay;
- (void)remoteCameraDidChange:(RemoteCameraProperty)property;
- (void)remoteCameraErrorDidOccur:(RemoteCameraError)error;

@end

@protocol RemoteCameraControl <NSObject>

@property (nonatomic, readonly) BOOL isSupportedVersion;
@property (nonatomic, readonly) BOOL isRunning;

- (id<RemoteCameraControl>)remoteCameraControl;
- (CapabilityPriorityLevel)remoteCameraControlPriority;

- (UIView *)startRemoteCamera;
- (UIView *)startRemoteCameraWithSettings:(nullable NSDictionary<NSString *, id> *)settings;
- (void)stopRemoteCamera;
- (void)setLensFacing:(int)lensFacing;
- (void)setMicMute:(BOOL)micMute;
- (void)setRemoteCameraDelegate:(__weak id<RemoteCameraControlDelegate>)delegate;

@end

#endif /* RemoteCameraControl_h */
