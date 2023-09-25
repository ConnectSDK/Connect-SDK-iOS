//
//  DevicePicker.h
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

#import <UIKit/UIKit.h>
#import "DevicePickerDelegate.h"
#import "DiscoveryManagerDelegate.h"
#import "ConnectableDevice.h"

/*!
 * ###Overview
 * The DevicePicker is provided by the DiscoveryManager as a simple way for you to present a list of available devices to your users.
 *
 * ###In Depth
 * The DevicePicker takes a sender parameter on the showPicker method. The sender parameter is used to display a popover from a particular UIView on iPads.
 *
 * You should not attempt to instantiate the DevicePicker on your own. Instead, get the reference from the DeviceManager with [[DeviceManager sharedManager] devicePicker];
 */
@interface DevicePicker : NSObject <DiscoveryManagerDelegate, UIPopoverControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

/*! Delegate that receives selected/cancelled messages. */
@property (nonatomic, weak) id<DevicePickerDelegate> delegate;

/*!
 * When the showPicker method is called, it can animate onto the screen if this value is set to YES. This value will also be used to determine if the picker should animate when it is dismissed.
 */
@property (nonatomic) BOOL shouldAnimatePicker;

/*!
 * When the device is rotated, the DevicePicker can automatically adjust the view to compenstate. Default is NO.
 */
@property (nonatomic) BOOL shouldAutoRotate;

/*!
 * If you wish to show a checkmark next to a device in the picker, you can set that device object to currentDevice. The setter for currentDevice will also reload the tableView in the picker.
 */
@property (nonatomic, weak) ConnectableDevice *currentDevice;

/*!
 * This method will animate the picker onto the screen. On iPad, the picker will appear as a popover view and will animate from the sender object, if you provide one. On iPhone, the picker will appear as a full-screen table view that will animate up from the bottom of the screen. This picker will animate in real time with additions, losses, and updates of ConnectableDevices.
 *
 * @param sender On iPad, this should be a UIView for the popover view to animate from. On iPhone, this property is ignored.
 */
- (void) showPicker:(id)sender;

/*!
 * This method will animate an action sheet onto the screen containing a button for each discovered ConnectableDevice. Due to the nature of action sheets, it is not possible to update the action sheet after it has appeared. It is recommended to use the showPicker: method if you want a picker that will update in real time.
 *
 * @param sender The UIView that the action sheet should appear in
 */
- (void) showActionSheet:(id)sender;

@end
