//
//  Prefix header
//
//  The contents of this file are implicitly included at the beginning of every source file.
//
//  Copyright (c) 2015 LG Electronics.
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

#define CONNECT_SDK_VERSION @"1.6.0"

#ifdef __OBJC__
    #import <Foundation/Foundation.h>
#endif

// Uncomment this line to enable SDK logging
//#define CONNECT_SDK_ENABLE_LOG

#ifndef kConnectSDKWirelessSSIDChanged
#define kConnectSDKWirelessSSIDChanged @"Connect_SDK_Wireless_SSID_Changed"
#endif

#ifdef CONNECT_SDK_ENABLE_LOG
    // credit: http://stackoverflow.com/a/969291/2715
    #ifdef DEBUG
    #   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
    #else
    #   define DLog(...)
    #endif
#else
    #   define DLog(...)
#endif
