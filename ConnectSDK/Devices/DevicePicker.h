//
//  DevicePicker.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DevicePickerDelegate.h"
#import "DiscoveryManagerDelegate.h"
#import "ConnectableDevice.h"

@interface DevicePicker : NSObject <DiscoveryManagerDelegate, UIPopoverControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) id<DevicePickerDelegate> delegate;
@property (nonatomic) BOOL shouldAnimatePicker;
@property (nonatomic, strong) ConnectableDevice *currentDevice;

- (void) showPicker:(id)sender;
- (void) showActionSheet:(id)sender;

@end
