//
//  ConnectionManager.h
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

#ifndef ConnectionManager_h
#define ConnectionManager_h

#import <Foundation/Foundation.h>

#import "ConnectableDevice.h"

typedef NS_ENUM(int, ConnectionState) {
    kConnectionStateNone,
    kConnectionStateConnecting,
    kConnectionStateConnected,
    kConnectionStateDisconnecting
};

typedef NS_ENUM(int, ConnectionError) {
    kConnectionErrorUnknown,
    kConnectionErrorConnectionClosed,
    kConnectionErrorDeviceShutdown,
    kConnectionErrorRendererTerminated
};

typedef NS_ENUM(int, ServiceType) {
    kServiceTypeScreenMirroring,
    kServiceTypeRemoteCamera
};

@protocol ConnectionManagerDelegate <NSObject>

- (void)onPairingRequested;
- (void)onPairingRejected;
- (void)onConnectionFailed:(NSString *)message;
- (void)onConnectionCompleted:(NSDictionary *)values;
- (void)onReceivePlayCommand:(NSDictionary *)values;
- (void)onReceiveStopCommand:(NSDictionary *)values;
- (void)onReceiveGetParameter:(NSDictionary *)values;
- (void)onReceiveSetParameter:(NSDictionary *)values;
- (void)onError:(ConnectionError)error message:(NSString *)message;

@end

@interface ConnectionManager : NSObject

@property (nonatomic, weak) id<ConnectionManagerDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)openConnection:(ServiceType)type device:(ConnectableDevice *)device;
- (void)setSourceDeviceInfo:(NSDictionary *)sourceInfo deviceInfo:(NSDictionary *)deviceInfo;
- (void)subscribe;
- (void)sendGetParameter;
- (void)sendSetParameter:(NSDictionary *)values;
- (void)sendSetParameter:(NSDictionary *)values ignoreResult:(BOOL)ignoreResult ;
- (void)sendGetParameterResponse:(NSDictionary *)values;
- (void)sendSetParameterResponse:(NSDictionary *)values;
- (void)closeConnection;

@end

#endif /* ConnectionManager_h */
