//
//  DevicePickerDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DevicePicker;
@class ConnectableDevice;

@protocol DevicePickerDelegate <NSObject>

- (void) devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device;

@optional

- (void) devicePicker:(DevicePicker *)picker didCancelWithError:(NSError*)error;

@end
