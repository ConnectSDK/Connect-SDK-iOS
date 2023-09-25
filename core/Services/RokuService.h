//
//  RokuService.h
//  ConnectSDK
//
//  Created by Jeremy White on 2/14/14.
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

#define kConnectSDKRokuServiceId @"Roku"

#import "DIALService.h"
#import "MediaControl.h"
#import "MediaPlayer.h"
#import "KeyControl.h"
#import "TextInputControl.h"

enum
{
    RokuKeyCodeHome,
    RokuKeyCodeRewind,
    RokuKeyCodeFastForward,
    RokuKeyCodePlay,
    RokuKeyCodeSelect,
    RokuKeyCodeLeft,
    RokuKeyCodeRight,
    RokuKeyCodeDown,
    RokuKeyCodeUp,
    RokuKeyCodeBack,
    RokuKeyCodeInstantReplay,
    RokuKeyCodeInfo,
    RokuKeyCodeBackspace,
    RokuKeyCodeSearch,
    RokuKeyCodeEnter,
    RokuKeyCodeLiteral
};

// @cond INTERNAL
typedef NSUInteger RokuKeyCode;

#define kRokuKeyCodes @[ @"Home", @"Rev", @"Fwd", @"Play", @"Select", @"Left", @"Right", @"Down", @"Up", @"Back", @"InstantReplay", @"Info", @"Backspace", @"Search", @"Enter", @"Lit_" ]
// @endcond

@interface RokuService : DeviceService <Launcher, MediaPlayer, MediaControl, KeyControl, TextInputControl>

// @cond INTERNAL
- (void)sendKeyCode:(RokuKeyCode)keyCode success:(SuccessBlock)success failure:(FailureBlock)failure;
// @endcond

+ (void) registerApp:(NSString *)appId;

@end
