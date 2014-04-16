//
//  DevicePickerDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics.
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

@class DevicePicker;
@class ConnectableDevice;

/*!
 * The DevicePickerDelegate will receive a message when the user cancels or selects a ConnectableDevice from the DevicePicker list. This is the preferred method of selecting a device from DiscoveryManager.
 */
@protocol DevicePickerDelegate <NSObject>

/*!
 * When the user selects a ConnectableDevice from the DevicePicker's list, this method will be called with the selected ConnectableDevice.
 *
 * @param picker DevicePicker that device was selected from
 * @param device ConnectableDevice that was selected by the user
 */
- (void) devicePicker:(DevicePicker *)picker didSelectDevice:(ConnectableDevice *)device;

@optional

/*!
 * This method is called if the user presses the cancel button in the picker or if Connect SDK forces a cancellation. If Connect SDK forces a cancellation, there will be an NSError object passed with the reason.
 *
 * @param picker DevicePicker that was cancelled
 * @param error NSError with a description of the failure
 */
- (void) devicePicker:(DevicePicker *)picker didCancelWithError:(NSError*)error;

@end
