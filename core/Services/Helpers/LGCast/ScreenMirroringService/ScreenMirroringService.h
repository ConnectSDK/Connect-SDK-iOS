//
//  ScreenMirroringService.h
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

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

#import "ScreenMirroringControl.h"
#import "ConnectableDevice.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ScreenMirroringServiceDelegate <NSObject>
- (void)screenMirroringDidStart:(BOOL)result;
- (void)screenMirroringDidStop:(BOOL)result;
- (void)screenMirroringErrorDidOccur:(ScreenMirroringError)error;
@end

extern NSString *const kSMKeyMirroring;
extern NSString *const kSMKeyResult;

extern NSString *const kSMKeyDisplayOrientation;

extern NSString *const kSMValueOrientationPortrait;
extern NSString *const kSMValueOrientationLandscape;

@interface ScreenMirroringService: NSObject

@property (nonatomic, weak) id<ScreenMirroringServiceDelegate> delegate;
@property (readonly) BOOL isRunning;

+ (instancetype)sharedInstance;

- (void)startMirroring:(ConnectableDevice *)device settings:(nullable NSDictionary<NSString *, id> *)settings;
- (void)stopMirroring;
- (void)pushSampleBuffer:(CMSampleBufferRef)sampleBuffer with:(RPSampleBufferType)sampleBufferType;

@end

NS_ASSUME_NONNULL_END
