//
//  SocketListener.h
//  Connect SDK
//
//  Created by Mykhailo Vorontsov on 3/29/13.
//	Copyright (c) 2014 LG Electronics.
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

@class SSDPSocketListener;

@protocol SocketListenerDelegate <NSObject>

@optional

- (void)socket:(SSDPSocketListener *)aSocket didReceiveData:(NSData *)aData fromAddress:(NSString *)anAddress;
- (void)socket:(SSDPSocketListener *)aSocket didEncounterError:(NSError *)anError;

@end

@interface SSDPSocketListener : NSObject

@property (nonatomic, assign) id<SocketListenerDelegate> delegate;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, readwrite) NSInteger port;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readwrite) dispatch_queue_t workQueue;
@property (nonatomic, readwrite) dispatch_queue_t delegateQueue;
@property (nonatomic, readwrite, getter = isListenToAnyMessages) BOOL listenToSpecifiedAddressOnly;

- (instancetype)initWithAddress:(NSString *)anAddress andPort:(NSInteger)aPort;
- (void)sendData:(NSData *)aData toAddress:(NSString *)anAddress andPort:(NSUInteger)aPort;
- (void)open;
- (void)close;

@end
