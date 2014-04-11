//
//  SocketListener.h
//  SSDPDiscoveryProto
//
//  Created by Mykhailo Vorontsov on 3/29/13.
//	Copyright (c) 2014 LG Electronics, Inc.
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

- (id)initWithAddress:(NSString *)anAddress andPort:(NSInteger)aPort;
- (void)sendData:(NSData *)aData toAddress:(NSString *)anAddress andPort:(NSUInteger)aPort;
- (void)open;
- (void)close;

@end
