//
//  NetcastTVService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#define kConnectSDKNetcastTVServiceId @"Netcast TV"

#import <UIKit/UIKit.h>
#import "DeviceService.h"
#import "Launcher.h"
#import "NetcastTVServiceConfig.h"
#import "DIALService.h"
#import "DLNAService.h"
#import "MediaControl.h"
#import "ExternalInputControl.h"
#import "VolumeControl.h"
#import "TVControl.h"
#import "KeyControl.h"
#import "MouseControl.h"
#import "TextInputControl.h"
#import "PowerControl.h"

@interface NetcastTVService : DeviceService <Launcher, MediaPlayer, MediaControl, VolumeControl, TVControl, KeyControl, MouseControl, PowerControl, ExternalInputControl, TextInputControl>

// @cond INTERNAL
/// The base class' @c serviceConfig property downcast to
/// @c NetcastTVServiceConfig if possible, or nil.
@property (nonatomic, strong) NetcastTVServiceConfig *netcastTVServiceConfig;

// these objects are maintained to provide certain functionality without requiring pairing
@property (nonatomic, strong, readonly) DIALService *dialService;
@property (nonatomic, strong, readonly) DLNAService *dlnaService;

// Defined at http://developer.lgappstv.com/TV_HELP/topic/lge.tvsdk.references.book/html/UDAP/UDAP/Annex%20A%20Table%20of%20virtual%20key%20codes%20on%20remote%20Controller.htm#_Annex_A_Table
enum {
    NetcastTVKeyCodePower = 1,
    NetcastTVKeyCodeNumber0 = 2,
    NetcastTVKeyCodeNumber1 = 3,
    NetcastTVKeyCodeNumber2 = 4,
    NetcastTVKeyCodeNumber3 = 5,
    NetcastTVKeyCodeNumber4 = 6,
    NetcastTVKeyCodeNumber5 = 7,
    NetcastTVKeyCodeNumber6 = 8,
    NetcastTVKeyCodeNumber7 = 9,
    NetcastTVKeyCodeNumber8 = 10,
    NetcastTVKeyCodeNumber9 = 11,
    NetcastTVKeyCodeUp = 12,
    NetcastTVKeyCodeDown = 13,
    NetcastTVKeyCodeLeft = 14,
    NetcastTVKeyCodeRight = 15,
    NetcastTVKeyCodeOK = 20,
    NetcastTVKeyCodeHome = 21,
    NetcastTVKeyCodeMenu = 22,
    NetcastTVKeyCodeBack = 23,
    NetcastTVKeyCodeVolumeUp = 24,
    NetcastTVKeyCodeVolumeDown = 25,
    NetcastTVKeyCodeMute = 26, // Toggle
    NetcastTVKeyCodeChannelUp = 27,
    NetcastTVKeyCodeChannelDown = 28,
    NetcastTVKeyCodeBlue = 29,
    NetcastTVKeyCodeGreen = 30,
    NetcastTVKeyCodeRed = 31,
    NetcastTVKeyCodeYellow = 32,
    NetcastTVKeyCodePlay = 33,
    NetcastTVKeyCodePause = 34,
    NetcastTVKeyCodeStop = 35,
    NetcastTVKeyCodeFastForward = 36,
    NetcastTVKeyCodeRewind = 37,
    NetcastTVKeyCodeSkipForward = 38,
    NetcastTVKeyCodeSkipBackward = 39,
    NetcastTVKeyCodeRecord = 40,
    NetcastTVKeyCodeRecordingList = 41,
    NetcastTVKeyCodeRepeat = 42,
    NetcastTVKeyCodeLiveTV = 43,
    NetcastTVKeyCodeEPG = 44,
    NetcastTVKeyCodeCurrentProgramInfo = 45,
    NetcastTVKeyCodeAspectRatio = 46,
    NetcastTVKeyCodeExternalInput = 47,
    NetcastTVKeyCodePIP = 48,
    NetcastTVKeyCodeSubtitle = 49, // Toggle
    NetcastTVKeyCodeProgramList = 50,
    NetcastTVKeyCodeTeleText = 51,
    NetcastTVKeyCodeMark = 52,
    NetcastTVKeyCode3DVideo = 400,
    NetcastTVKeyCode3DLR = 401,
    NetcastTVKeyCodeDash = 402, // (-)
    NetcastTVKeyCodePreviousChannel = 403,
    NetcastTVKeyCodeFavoriteChannel = 404,
    NetcastTVKeyCodeQuickMenu = 405,
    NetcastTVKeyCodeTextOption = 406,
    NetcastTVKeyCodeAudioDescription = 407,
    NetcastTVKeyCodeNetcast = 408,
    NetcastTVKeyCodeEnergySaving = 409,
    NetcastTVKeyCodeAVMode = 410,
    NetcastTVKeyCodeSIMPLINK = 411,
    NetcastTVKeyCodeExit = 412,
    NetcastTVKeyCodeReservationProgramsList = 413,
    NetcastTVKeyCodePIPChannelUp = 414,
    NetcastTVKeyCodePIPChannelDown = 415,
    NetcastTVKeyCodeVideoSwitch = 416,
    NetcastTVKeyCodeMyApps = 417
};

typedef NSUInteger NetcastTVKeyCode;

- (void) pairWithData:(NSString *)pairingData;
// @endcond

@end
