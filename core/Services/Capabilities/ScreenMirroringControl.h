//
//  ScreenMirroringControl.h
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

#ifndef ScreenMirroringControl_h
#define ScreenMirroringControl_h

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>
#import "Capability.h"

#define kScreenMirroringControlAny @"ScreenMirroringControl.Any"

#define kScreenMirroringControlScreenMirroring @"ScreenMirroringControl.ScreenMirroring"

#define kScreenMirroringControlCapabilities @[\
    kScreenMirroringControlScreenMirroring\
]

typedef NS_ENUM(int, ScreenMirroringError) {
    ScreenMirroringErrorGeneric,
    ScreenMirroringErrorConnectionClosed,
    ScreenMirroringErrorDeviceShutdown,
    ScreenMirroringErrorRendererTerminated
};

@protocol ScreenMirroringControlDelegate <NSObject>

- (void)screenMirroringDidStart:(BOOL)result;
- (void)screenMirroringDidStop:(BOOL)result;
- (void)screenMirroringErrorDidOccur:(ScreenMirroringError)error;

@end

@protocol ScreenMirroringControl <NSObject>

- (id<ScreenMirroringControl>)screenMirroringControl;
- (CapabilityPriorityLevel)screenMirroringControlPriority;

- (void)startScreenMirroring;
- (void)startScreenMirroringWithSettings:(nullable NSDictionary<NSString *, id> *)settings;
- (void)pushSampleBuffer:(CMSampleBufferRef)sampleBuffer with:(RPSampleBufferType)sampleBufferType;
- (void)stopScreenMirroring;
- (void)setScreenMirroringDelegate:(__weak id<ScreenMirroringControlDelegate>)delegate;

@end

#endif /* ScreenMirroringControl_h */
