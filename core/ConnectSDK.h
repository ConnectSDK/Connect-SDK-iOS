//
//  ConnectSDK.h
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

#import "DiscoveryManager.h"
#import "DiscoveryManagerDelegate.h"
#import "DiscoveryProviderDelegate.h"

#import "ConnectableDevice.h"
#import "ConnectableDeviceDelegate.h"

#import "DevicePicker.h"
#import "DevicePickerDelegate.h"

#import "ServiceAsyncCommand.h"
#import "ServiceCommand.h"
#import "ServiceCommandDelegate.h"
#import "ServiceSubscription.h"

#import "CapabilityFilter.h"
#import "ExternalInputControl.h"
#import "KeyControl.h"
#import "TextInputControl.h"
#import "Launcher.h"
#import "MediaControl.h"
#import "PlayListControl.h"
#import "MediaPlayer.h"
#import "MouseControl.h"
#import "PowerControl.h"
#import "SubtitleInfo.h"
#import "ToastControl.h"
#import "TVControl.h"
#import "VolumeControl.h"
#import "WebAppLauncher.h"

#import "AppInfo.h"
#import "ChannelInfo.h"
#import "ExternalInputInfo.h"
#import "ImageInfo.h"
#import "MediaInfo.h"
#import "TextInputStatusInfo.h"
#import "ProgramInfo.h"
#import "LaunchSession.h"
#import "WebAppSession.h"

@interface ConnectSDK : NSObject

@end
