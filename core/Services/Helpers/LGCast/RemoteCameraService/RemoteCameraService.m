//
//  RemoteCameraService.m
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

#import "ConnectionManager.h"

#import "RemoteCameraService.h"
#import "CameraParameter.h"
#import "CameraSourceCapability.h"
#import "CameraSinkCapability.h"
#import "MobileCapability.h"

NSString *const kRCKeyCamera = @"camera";

NSString *const kRCKeyResult = @"result";

NSString *const kRCKeyVideoPort = @"videoPort";
NSString *const kRCKeyAudioPort = @"audioPort";
NSString *const kRCKeyWidth = @"width";
NSString *const kRCKeyHeight = @"height";

NSString *const kRCKeyFacing = @"facing";
NSString *const kRCKeyAudio = @"audio";
NSString *const kRCKeyBrightness = @"brightness";
NSString *const kRCKeyWhiteBalance = @"whiteBalance";
NSString *const kRCKeyAutoWhiteBalance = @"autoWhiteBalance";
NSString *const kRCKeyRotation = @"rotation";

@interface RemoteCameraService () <ConnectionManagerDelegate, LGCastCameraApiDelegate>

@property ConnectionManager *connectionManager;
@property BOOL isRunning;
@property BOOL isPlaying;

@property CameraParameter *cameraParameter;
@property CameraSourceCapability *sourceCapability;
@property CameraSinkCapability *sinkCapability;

@end

@implementation RemoteCameraService

+ (instancetype)sharedInstance {
    static RemoteCameraService *shared = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        shared = [[RemoteCameraService alloc] initPrivate];
    });
    
    return shared;
}

- (instancetype)init {
    return [[self class] sharedInstance];
}

- (instancetype)initPrivate {
    self = [super init];
    
    _isRunning = NO;
    _isPlaying = NO;
    _connectionManager = ConnectionManager.sharedInstance;
    _connectionManager.delegate = self;
    [[LGCastCameraApi shared] setDelegate:self];
    
    return self;
}

- (UIView *)startRemoteCamera:(ConnectableDevice *)device settings:(nullable NSDictionary<NSString *, id> *)settings {
    [Log infoLGCast:@"startRemoteCamera"];
    
    UIView *previewView;
    if (self.isRunning == NO) {
        self.isRunning = YES;
        self.isPlaying = NO;
        previewView = [[LGCastCameraApi shared] createCameraPreviewView:nil];

        if (settings != nil) {
            if (settings[kRemoteCameraSettingsMicMute] != nil) {
                bool isMicMute = [settings[kRemoteCameraSettingsMicMute] boolValue];
                [[LGCastCameraApi shared] muteMicrophone:isMicMute];
            }
            
            if (settings[kRemoteCameraSettingsLensFacing] != nil ) {
                int lensFacing = [settings[kRemoteCameraSettingsLensFacing] intValue];
                [[LGCastCameraApi shared] changeCameraPosition:lensFacing];
            }
        }
        
        [self updateCameraParameter];
        [_connectionManager openConnection:kServiceTypeRemoteCamera device:device];
    } else {
        [self sendStartEvent:NO];
    }
    
    return previewView;
}

- (void)stopRemoteCamera {
    [Log infoLGCast:@"stopRemoteCamera"];
    
    if (self.isRunning == YES) {
        self.isRunning = NO;
        self.isPlaying = NO;
        [[LGCastCameraApi shared] stopRemoteCamera];
        [_connectionManager closeConnection];
        [self sendStopEvent:YES];
    } else {
        [self sendStopEvent:NO];
    }
}

- (void)setLensFacing:(int)lensFacing {
    [Log infoLGCast:@"setLensFacing"];
    
    BOOL result = [[LGCastCameraApi shared] changeCameraPosition:lensFacing];
    if (_isPlaying && result) {
        NSDictionary *values = [_cameraParameter toNSDictionaryFacing:lensFacing];
        [_connectionManager sendSetParameter:values];
    }
}

- (void)setMicMute:(BOOL)micMute {
    [Log infoLGCast:@"setMicMute"];
    
    BOOL result = [[LGCastCameraApi shared] muteMicrophone:micMute];
    if (_isPlaying && result) {
        NSDictionary *values = [_cameraParameter toNSDictionaryAudio:micMute];
        [_connectionManager sendSetParameter:values];
    }
}

// MARK: PRIVATE FUNCTIONS
- (void)updateCameraParameter {
    if (_cameraParameter == nil) {
        _cameraParameter = [[CameraParameter alloc] init];
    }

    LGCastCameraParameterInfo *info = [[LGCastCameraApi shared] getCameraProperties];
    if (info == nil) { return; }

    _cameraParameter.audio = info.audio == LGCastCamperaPropertyStatusEnable ? YES : NO;
    _cameraParameter.autoWhiteBalance = info.autoWhiteBalance == LGCastCamperaPropertyStatusEnable ? YES : NO;
    _cameraParameter.brightness = info.brightness;
    _cameraParameter.facing = info.facing;
    _cameraParameter.whiteBalance = info.whiteBalance;
    _cameraParameter.rotation = info.rotation;
    _cameraParameter.width = info.width;
    _cameraParameter.height = info.height;
}

// MARK: ConnectionManagerDelegate

- (void)onPairingRequested {
    [Log infoLGCast:@"onPairingRequested"];
    
    [self sendPairEvent];
}

- (void)onPairingRejected {
    [Log infoLGCast:@"onPairingRejected"];
    
    self.isRunning = NO;
    [self sendStartEvent:NO];
}

- (void)onConnectionFailed:(NSString *)message {
    [Log infoLGCast:@"onConnectionFailed"];
    
    self.isRunning = NO;
    self.isPlaying = NO;
    [self sendStartEvent:NO];
}

- (void)onConnectionCompleted:(NSDictionary *)values {
    [Log infoLGCast:@"onConnectionCompleted"];
    
    _sinkCapability = [[CameraSinkCapability alloc] initWithJSON:values];
    
    _sourceCapability = [[CameraSourceCapability alloc] init];
    NSArray<LGCastSecurityKey *> *keys = [[LGCastCameraApi shared] generateCameraMasterKey:_sinkCapability.publicKey];
    [_sourceCapability setSecurityKeys:keys];
    _sourceCapability.resolutions = [[LGCastCameraApi shared] getSupportedResolutions];
    
    MobileCapability *mobileCapability = [[MobileCapability alloc] init];
    
    [_connectionManager setSourceDeviceInfo:[_sourceCapability toNSDictionary]
                                 deviceInfo:[mobileCapability toNSDictionary]];
    [self sendStartEvent:YES];
}

- (void)onReceivePlayCommand:(NSDictionary *)values {
    [Log infoLGCast:@"onReceivePlayCommand"];
    
    NSDictionary *cameraObj = values[kRCKeyCamera];
    
    if (cameraObj == nil) {
        [Log errorLGCast:@"invalid parameter"];
        return;
    }
    
    int videoPort = [cameraObj[kRCKeyVideoPort] intValue];
    int audioPort = [cameraObj[kRCKeyAudioPort] intValue];
    int width = [cameraObj[kRCKeyWidth] intValue];
    int height = [cameraObj[kRCKeyHeight] intValue];
    
    LGCastCameraResolutionInfo *resolution = [[LGCastCameraResolutionInfo alloc] init];
    resolution.width = width;
    resolution.height = height;
    [[LGCastCameraApi shared] setResolution:resolution];
    
    LGCastDeviceSettings *settings = [[LGCastDeviceSettings alloc] init];
    settings.host = _sinkCapability.ipAddress;
    settings.videoPort = videoPort;
    settings.audioPort = audioPort;
    
    [[LGCastCameraApi shared] startRemoteCamera:settings];
    [self sendPlayEvent];
    self.isPlaying = YES;
}

- (void)onReceiveStopCommand:(NSDictionary *)values {
    [Log infoLGCast:@"onReceiveStopCommand"];
    
    [[LGCastCameraApi shared] stopRemoteCamera];
    self.isPlaying = NO;
}

- (void)onReceiveGetParameter:(NSDictionary *)values {
    [Log infoLGCast:@"onReceiveGetParameter"];
    
    [self updateCameraParameter];
    [_connectionManager sendGetParameterResponse:[_cameraParameter toNSDictionary]];
}

- (void)onReceiveSetParameter:(NSDictionary *)values {
    [Log infoLGCast:@"onReceiveSetParameter"];
    
    NSDictionary *cameraObj = values[kRCKeyCamera];
    
    if (cameraObj == nil) {
        [Log errorLGCast:@"invalid parameter"];
        return;
    }
    
    BOOL result = NO;
    NSDictionary *response;
    
    if (cameraObj[kRCKeyBrightness]) {
        int brightness = [cameraObj[kRCKeyBrightness] intValue];
        
        result = [[LGCastCameraApi shared] setCameraPropertiesWithProperty:LGCastCameraPropertyBrightness value:brightness];
        response = [_cameraParameter toNSDictionaryBritnessResult:result brightness:brightness];
        [self sendChangeEvent:RemoteCameraPropertyBrightness];
    }
    
    if (cameraObj[kRCKeyWhiteBalance]) {
        int whiteBalance = [cameraObj[kRCKeyWhiteBalance] intValue];
        
        result = [[LGCastCameraApi shared] setCameraPropertiesWithProperty:LGCastCameraPropertyWhitebalance value:whiteBalance];
        response = [_cameraParameter toNSDictionaryWhiteBalanceResult:result whiteBalance:whiteBalance];
        
        [self sendChangeEvent:RemoteCameraPropertyWhiteBalance];
    }
    
    if (cameraObj[kRCKeyAutoWhiteBalance]) {
        BOOL autoWhiteBalance = [cameraObj[kRCKeyAutoWhiteBalance] boolValue];
        
        result = [[LGCastCameraApi shared] setCameraPropertiesWithProperty:LGCastCameraPropertyAutoWhiteBalance value:autoWhiteBalance];
        response = [_cameraParameter toNSDictionaryAutoWhiteBalanceResult:result autoWhiteBalance:autoWhiteBalance];
    }
    
    if (values[kRCKeyFacing]) {
        int facing = [values[kRCKeyFacing] intValue];
        
        result = [[LGCastCameraApi shared] setCameraPropertiesWithProperty:LGCastCameraPropertyFacing value:facing];
        response = [_cameraParameter toNSDictionaryFacingResult:result facing:facing];
    }
    
    if (cameraObj[kRCKeyAudio]) {
        BOOL audio = [cameraObj[kRCKeyAudio] boolValue];
        
        result = [[LGCastCameraApi shared] setCameraPropertiesWithProperty:LGCastCameraPropertyAudio value:audio];
        response = [_cameraParameter toNSDictionaryAudioResult:result audio:audio];
    }
    
    if (response != nil) {
        [_connectionManager sendSetParameterResponse:response];
    }
}

- (void)onError:(ConnectionError)error message:(NSString *)message {
    [Log errorLGCast:[NSString stringWithFormat:@"onError %d %@", error, message]];
    
    RemoteCameraError controlError = RemoteCameraErrorGeneric;
    switch (error) {
        case kConnectionErrorUnknown:
            [Log errorLGCast:@"kConnectionErrorUnknown"];
            controlError = RemoteCameraErrorGeneric;
            break;
        case kConnectionErrorConnectionClosed:
            [Log errorLGCast:@"kConnectionErrorConnectionClosed"];

            controlError = RemoteCameraErrorConnectionClosed;
            break;
        case kConnectionErrorDeviceShutdown:
            [Log errorLGCast:@"kConnectionErrorDeviceShutdown"];

            controlError = RemoteCameraErrorDeviceShutdown;
            break;
        case kConnectionErrorRendererTerminated:
            [Log errorLGCast:@"kConnectionErrorRendererTerminated"];
            controlError = RemoteCameraErrorRendererTerminated;
            break;
        default:
            break;
    }
    
    self.isRunning = NO;
    self.isPlaying = NO;
    [[LGCastCameraApi shared] stopRemoteCamera];
    [_connectionManager closeConnection];
    
    [self sendErrorEvent:controlError];
}

// MARK: LGCastCameraApiDelegate

- (void)lgcastCameraDidChangeWithProperty:(LGCastCameraProperty)property {
    [Log infoLGCast:@"lgcastCameraDidChangeWithProperty"];
    
    if (!self.isPlaying) {
        return;
    }
    
    if (property == LGCastCameraPropertyRotation) {
        [self updateCameraParameter];
        [_connectionManager sendSetParameter:@{
            kRCKeyRotation: [NSNumber numberWithLong:_cameraParameter.rotation]
        }];
    } else {
        RemoteCameraProperty type = RemoteCameraPropertyUnknown;
        
        switch (type) {
            case LGCastCameraPropertyBrightness:
                type = RemoteCameraPropertyBrightness;
                break;
            case LGCastCameraPropertyWhitebalance:
                type = RemoteCameraPropertyWhiteBalance;
                break;
            default:
                break;
        }

        [self sendChangeEvent:type];
    }
}

- (void)lgcastCameraDidPlay {
    [Log infoLGCast:@"lgcastCameraDidPlay"];
    
    [self sendPlayEvent];
}

- (void)lgcastCameraErrorDidOccurWithError:(LGCastCameraError)error {
    [Log errorLGCast:[NSString stringWithFormat:@"lgcastCameraErrorDidOccurWithError %ld", (long)error]];
    
    self.isRunning = NO;
    [self sendErrorEvent:error];
}

- (void)sendPairEvent {
    if (_delegate && [_delegate respondsToSelector:@selector(remoteCameraDidPair)]) {
        [_delegate remoteCameraDidPair];
    }
}

- (void)sendStartEvent:(BOOL)result {
    if (_delegate && [_delegate respondsToSelector:@selector(remoteCameraDidStart:)]) {
        [_delegate remoteCameraDidStart:result];
    }
}

- (void)sendStopEvent:(BOOL)result {
    if (_delegate && [_delegate respondsToSelector:@selector(remoteCameraDidStop:)]) {
        [_delegate remoteCameraDidStop:result];
    }
}

- (void)sendPlayEvent {
    if (_delegate && [_delegate respondsToSelector:@selector(remoteCameraDidPlay)]) {
        [_delegate remoteCameraDidPlay];
    }
}

- (void)sendChangeEvent:(RemoteCameraProperty)property {
    if (_delegate && [_delegate respondsToSelector:@selector(remoteCameraDidChange:)]) {
        [_delegate remoteCameraDidChange:property];
    }
}

- (void)sendErrorEvent:(RemoteCameraError)error {
    if (_delegate && [_delegate respondsToSelector:@selector(remoteCameraErrorDidOccur:)]) {
        [_delegate remoteCameraErrorDidOccur:error];
    }
}

@end
