//
// Created by Jeremy White on 12/23/13.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DeviceServicePairingTypeNone = 0,
    DeviceServicePairingTypeFirstScreen,
    DeviceServicePairingTypePinCode
} DeviceServicePairingType;

@class DeviceService;

@protocol DeviceServiceDelegate <NSObject>

@optional
- (void) deviceServiceConnectionRequired:(DeviceService *)service;
- (void) deviceServiceConnectionSuccess:(DeviceService*)service;
- (void) deviceService:(DeviceService *)service disconnectedWithError:(NSError*)error;
- (void) deviceService:(DeviceService *)service didFailConnectWithError:(NSError*)error;

- (void) deviceService:(DeviceService *)service pairingRequiredOfType:(DeviceServicePairingType)pairingType withData:(id)pairingData;
- (void) deviceServicePairingSuccess:(DeviceService*)service;
- (void) deviceService:(DeviceService *)service pairingFailedWithError:(NSError*)error;

@end
