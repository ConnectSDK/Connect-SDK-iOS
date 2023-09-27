//
//  ConnectionManager.m
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
#import <LGCast/LGCast-Swift.h>

#import "WebOSTVService.h"
#import "ConnectableDevice.h"
#import "ServiceSubscription.h"

#import "ConnectionManager.h"
#import "WebOSTVService+LGCast.h"

@interface ConnectionManager () <ConnectableDeviceDelegate>

@property ServiceType serviceType;
@property NSString *serviceName;
@property ConnectionState currentState;
@property ConnectableDevice *tvDevice;
@property WebOSTVService *service;
@property ServiceSubscription *commandSubscription;
@property ServiceSubscription *powerStateSubscription;
@property NSTimer *keepAliveTimer;
@property double keepAlivePeriod;

@property SuccessBlock nilSuccessBlock;
@property FailureBlock nilFailBlock;

@end

@implementation ConnectionManager

NSString *const kCMKeyScreenMirrroringService = @"mirroring";
NSString *const kCMKeyRemoteCameraService = @"camera";

NSString *const kCMKeyCommand = @"cmd";
NSString *const kCMKeySubscribed = @"subscribed";
NSString *const kCMKeyProcessing = @"processing";
NSString *const kCMKeyClientKey = @"clientKey";

NSString *const kCMKeyCommandPlay = @"PLAY";
NSString *const kCMKeyCommandStop = @"STOP";
NSString *const kCMKeyCommandTeardown = @"TEARDOWN";
NSString *const kCMKeyCommandSetParameter = @"SET_PARAMETER";
NSString *const kCMKeyCommandGetParameter = @"GET_PARAMETER";

NSString *const kCMValueRequestPowerOff = @"Request Power Off";

+ (instancetype)sharedInstance {
    static ConnectionManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
        
        shared.currentState = kConnectionStateNone;
        shared.keepAlivePeriod = 50;
        shared.nilSuccessBlock = ^(id responseObject) {};
        shared.nilFailBlock = ^(NSError* error) {};
    });
    
    return shared;
}

- (void)openConnection:(ServiceType)type device:(ConnectableDevice *)device {
    [Log infoLGCast: @"openConnection"];

    if (device == nil) return;
    
    _currentState = kConnectionStateConnecting;
    
    _serviceType = type;
    _serviceName = type == kServiceTypeScreenMirroring ? kCMKeyScreenMirrroringService : kCMKeyRemoteCameraService;
    _service = (WebOSTVService *)[device serviceWithName:kConnectSDKWebOSTVServiceId];
    
    _tvDevice = device;
    [_tvDevice setDelegate:self];
    [device connect];
}

- (void)sendGetParameter {
    [Log infoLGCast:@"sendGetParameter"];
    
    SuccessBlock successBlock = ^(NSDictionary *json) {
        if (json == nil) { return; }
        
        [self callOnConnectionCompleted:json];
    };
    
    FailureBlock failureBlock = ^(NSError *error) {
        if (error != nil) {
            [Log errorLGCast:error.localizedDescription];
            [self callOnConnectionFailed:@"sendGetParameter failure"];
        }
    };
    
    [_service sendGetParameterWithService:_serviceName success:successBlock failure:failureBlock];
}

- (void)sendSetParameter:(NSDictionary *)values {
    [self sendSetParameter:values ignoreResult:NO];
}


- (void)sendSetParameter:(NSDictionary *)values ignoreResult:(BOOL)ignoreResult {
    [Log infoLGCast:@"sendSetParameter"];
    
    FailureBlock failureBlock = ^(NSError *error) {
        if (error != nil) {
            [Log errorLGCast:error.localizedDescription];
            
            if (!ignoreResult) {
                [self callOnConnectionFailed:@"sendSetParameter failure"];
            }
        }
    };
    
    [_service sendSetParameterWithService:_serviceName sourceInfo:values deviceInfo:nil success:_nilSuccessBlock failure:failureBlock];
}

- (void)sendGetParameterResponse:(NSDictionary *)values {
    [Log infoLGCast:@"sendGetParameterResponse"];
    
    if (_currentState != kConnectionStateConnected) {
        [Log errorLGCast:[NSString stringWithFormat:@"Remote camera is not connected %d", _currentState]];
        return;
    }
    
    [_service sendGetParameterResponseWithService:_serviceName values:values success:_nilSuccessBlock failure:_nilFailBlock];
}

- (void)sendSetParameterResponse:(NSDictionary *)values {
    [Log infoLGCast:@"sendSetParameterResponse"];
    
    if (_currentState != kConnectionStateConnected) {
        [Log errorLGCast:[NSString stringWithFormat:@"Remote camera is not connected %d", _currentState]];
        return;
    }
    
    [_service sendSetParameterResponseWithService:_serviceName values:values success:_nilSuccessBlock failure:_nilFailBlock];
}

- (void)closeConnection {
    [Log infoLGCast:@"closeConnection"];
    
    if (_currentState == kConnectionStateDisconnecting) {
        return;
    }
    
    _currentState = kConnectionStateDisconnecting;
    
    if (_keepAliveTimer != nil) {
        [_keepAliveTimer invalidate];
    }
    
    [_service sendTeardownWithService:_serviceName success:_nilSuccessBlock failure:_nilFailBlock];
    
    if (_powerStateSubscription != nil) {
        [_powerStateSubscription unsubscribe];
    }
        
    if (_commandSubscription != nil) {
        [_commandSubscription unsubscribe];
    }
    
    if (_tvDevice != nil) {
        [_tvDevice disconnect];
        [_tvDevice setDelegate:nil];
        _tvDevice = nil;
    }
    
    _currentState = kConnectionStateNone;
}

- (void)setSourceDeviceInfo:(NSDictionary *)sourceInfo deviceInfo:(NSDictionary *)deviceInfo {
    [Log infoLGCast:@"setSourceDeviceInfo"];
    
    if (sourceInfo == nil || deviceInfo == nil) {
        [Log errorLGCast:@"setSourceDeviceInfo failure"];
        [self callOnConnectionFailed:@"setSourceDeviceInfo failure"];
        return;
    }
    
    SuccessBlock successBlock = ^(id responseObject) {
        [self sendKeepAlive];
    };
    
    FailureBlock failureBlock = ^(NSError *error) {
        if (error != nil) {
            [Log errorLGCast:error.localizedDescription];
            [self callOnConnectionFailed:@"sendSetParameter failure"];
        }
    };
    
    [_service sendSetParameterWithService:_serviceName sourceInfo:sourceInfo deviceInfo:deviceInfo success:successBlock failure:failureBlock];
}

- (void)sendKeepAlive {
    if (_keepAliveTimer != nil) {
        [_keepAliveTimer invalidate];
    }
    
    [_service sendKeepAliveWithService:_serviceName success:_nilSuccessBlock failure:_nilFailBlock];
    _keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:_keepAlivePeriod repeats:YES block:^(NSTimer * timer) {
        [self->_service sendKeepAliveWithService:_serviceName success:_nilSuccessBlock failure:_nilFailBlock];
    }];
}

- (void)subscribe {
    [Log infoLGCast:@"subscribe"];
    
    if (!(_currentState == kConnectionStateConnected || _currentState == kConnectionStateConnecting)) {
        [Log errorLGCast:[NSString stringWithFormat:@"Remote camera is not connected %d", _currentState]];
        return;
    }
    
    [self commandSubscribe];
    [self powerStateSubscribe];
}

- (void)commandSubscribe {
    SuccessBlock successBlock = ^(NSDictionary *response) {
        if (response == nil) { return; }
        
        if (!(self.currentState == kConnectionStateConnected || self.currentState == kConnectionStateConnecting)) {
            if (self.commandSubscription != nil) {
                [self.commandSubscription unsubscribe];
            }
            return;
        }
        
        if (response[kCMKeySubscribed]) {
            [self handleSubscribed:response];
        } else if (response[kCMKeyCommand]) {
            [self handleCommand:response];
        }
    };
    
    FailureBlock failureBlock = ^(NSError *error) {
        if (error != nil) {
            [Log errorLGCast:error.localizedDescription];
            [self callOnError:kConnectionErrorConnectionClosed message:@"subscribe error"];
        }
    };
    
    _commandSubscription = [_service subscribeCommandWithSuccess:successBlock failure:failureBlock];
}

- (void)powerStateSubscribe {
    SuccessBlock successBlock = ^(NSDictionary *response) {
        if (response == nil) { return; }
        
        NSString *processing = response[kCMKeyProcessing];
        if (processing != nil && [processing caseInsensitiveCompare:kCMValueRequestPowerOff] == NSOrderedSame) {
            [self callOnError:kConnectionErrorDeviceShutdown message:@"Device shut down"];
        }
    };
    
    _powerStateSubscription = [_service subscribePowerStateWithSuccess:successBlock failure:_nilFailBlock];
}

- (void)handleSubscribed:(NSDictionary *)response {
    [Log infoLGCast:@"handleSubscribed"];
    
    if (response[kCMKeySubscribed]) {
        [self sendConnect];
    } else {
        [self callOnConnectionFailed:@"subscribe failure"];
    }
}

- (void)handleCommand:(NSDictionary *)response {
    [Log infoLGCast:@"handleCommand"];
    
    NSString *clientKey = response[kCMKeyClientKey];
    NSString *currentClientKey = _service.webOSTVServiceConfig.clientKey;
    
    if (clientKey != nil && [clientKey caseInsensitiveCompare:currentClientKey] != NSOrderedSame) {
        [Log errorLGCast:@"Client Key not matched!"];
        return;
    }
    
    NSString *command = response[kCMKeyCommand];
    
    if (command == nil) return;
    
    if ([command caseInsensitiveCompare:kCMKeyCommandPlay] == NSOrderedSame) {
        [self callOnReceivePlayCommand:response];
    }
    
    if ([command caseInsensitiveCompare:kCMKeyCommandTeardown] == NSOrderedSame) {
        [self callOnError:kConnectionErrorRendererTerminated message:@"renderer terminated"];
    }
    
    if ([command caseInsensitiveCompare:kCMKeyCommandStop] == NSOrderedSame) {
        [self callOnReceiveStopCommand:response];
    }
    
    if ([command caseInsensitiveCompare:kCMKeyCommandGetParameter] == NSOrderedSame) {
        [self callOnReceiveGetParameter:response];
    }
    
    if ([command caseInsensitiveCompare:kCMKeyCommandSetParameter] == NSOrderedSame) {
        [self callOnReceiveSetParameter:response];
    }
}

- (void)sendConnect {
    [Log infoLGCast:@"sendConnect"];
    
    SuccessBlock successBlock = ^(id responseObject) {
        [self sendGetParameter];
    };
    
    FailureBlock failureBlock = ^(NSError *error) {
        if (error != nil) {
            [Log errorLGCast:error.localizedDescription];
            [self callOnConnectionFailed:@"sendConnect failure"];
        }
    };
    
    [_service sendConnectWithService:_serviceName success:successBlock failure:failureBlock];
}

- (void)callOnPairingRequested {
    
}

- (void)callOnPairingRejected {
    [Log infoLGCast:@"callOnPairingRejected"];
    _currentState = kConnectionStateNone;
    
    if (_delegate && [_delegate respondsToSelector:@selector(onPairingRejected)]) {
        [_delegate onPairingRejected];
    }
}

- (void)callOnConnectionFailed:(NSString *)message {
    [Log infoLGCast:@"callOnConnectionFailed"];
    
    [self closeConnection];
    _currentState = kConnectionStateNone;
    
    if (_delegate && [_delegate respondsToSelector:@selector(onConnectionFailed:)]) {
        [_delegate onConnectionFailed:message];
    }
}

- (void)callOnConnectionCompleted:(NSDictionary *)values {
    _currentState = kConnectionStateConnected;
    
    if (_delegate && [_delegate respondsToSelector:@selector(onConnectionCompleted:)]) {
        [_delegate onConnectionCompleted:values];
    }
}

- (void)callOnReceivePlayCommand:(NSDictionary *)values {
    if (_delegate && [_delegate respondsToSelector:@selector(onReceivePlayCommand:)]) {
        [_delegate onReceivePlayCommand:values];
    }
}

- (void)callOnReceiveStopCommand:(NSDictionary *)values {
    if (_delegate && [_delegate respondsToSelector:@selector(onReceiveStopCommand:)]) {
        [_delegate onReceiveStopCommand:values];
    }
}

- (void)callOnReceiveGetParameter:(NSDictionary *)values {
    if (_delegate && [_delegate respondsToSelector:@selector(onReceiveGetParameter:)]) {
        [_delegate onReceiveGetParameter:values];
    }
}

- (void)callOnReceiveSetParameter:(NSDictionary *)values {
    if (_delegate && [_delegate respondsToSelector:@selector(onReceiveSetParameter:)]) {
        [_delegate onReceiveSetParameter:values];
    }
}

- (void)callOnError:(ConnectionError)error message:(NSString *)message {
    [Log infoLGCast:@"callOnError"];
    
    [self closeConnection];
    _currentState = kConnectionStateNone;
    
    if (_delegate && [_delegate respondsToSelector:@selector(onError:message:)]) {
        [_delegate onError:error message:message];
    }
}

// MARK: ConnectableDeviceDelegate
- (void)connectableDeviceDisconnected:(ConnectableDevice *)device withError:(NSError *)error {
    [Log infoLGCast:[NSString stringWithFormat:@"connectableDevice disconnectedWithError: %@", error.localizedDescription]];
    
    switch (_currentState) {
        case kConnectionStateConnecting:
            [self callOnPairingRejected];
            break;
        case kConnectionStateConnected:
            [self callOnError:kConnectionErrorDeviceShutdown message:@"device disconnected"];
            break;
        default:
            [Log infoLGCast:[NSString stringWithFormat:@"Ignore event state: %d", _currentState]];
            break;
    }
}

- (void)connectableDeviceReady:(ConnectableDevice *)device {
    [Log infoLGCast:@"connectableDeviceReady"];
    
    [self subscribe];
}

- (void)connectableDevice:(ConnectableDevice *)device service:(DeviceService *)service pairingRequiredOfType:(int)pairingType withData:(id)pairingData {
    [Log infoLGCast:@"connectableDevice pairingRequiredOfType"];
    
    [self callOnPairingRequested];
}

@end
