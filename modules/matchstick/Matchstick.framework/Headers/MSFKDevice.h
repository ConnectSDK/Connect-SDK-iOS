//
// Created by Jiang Lu on 14-4-8.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>
/**
 * An object representing a first-screen device.
 *
 * @ingroup Discovery
 */
@interface MSFKDevice : NSObject <NSCopying, NSCoding>
//@interface MSFKDevice : NSObject <NSCopying, NSCoding>

/** The device's IPv4 address, in dot-notation. Used when making network requests. */
@property(nonatomic, copy) NSString *ipAddress;

/** The device's service port. */
@property(nonatomic) UInt32 servicePort;

/**
 * The device's unique ID. This is the USN (Unique Service Name) as reported by the SSDP protocol.
 */
@property(nonatomic, copy) NSString *deviceID;

/** The device's friendly name. This is a user-assignable name such as "Living Room". */
@property(nonatomic, copy) NSString *friendlyName;

/** The device's manufacturer name. */
@property(nonatomic, copy) NSString *manufacturer;

/** The device's model name. */
@property(nonatomic, copy) NSString *modelName;

/** An array of MSFKImage objects containing icons for the device. */
@property(nonatomic, copy) NSArray *icons;

/** Designated initializer. Constructs a new MSFKDevice with the given IP address.
 *
 * @param ipAddress The device's IPv4 address, in dot-notation.
 * @param servicePort The device's service port.
 */
- (id)initWithIPAddress:(NSString *)ipAddress servicePort:(UInt32)servicePort;

@end