//
//  RokuService.h
//  ConnectSDK
//
//  Created by Jeremy White on 2/14/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <ConnectSDK/ConnectSDK.h>
#import "DIALService.h"

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

typedef NSUInteger RokuKeyCode;

#define kRokuKeyCodes @[ @"Home", @"Rev", @"Fwd", @"Play", @"Select", @"Left", @"Right", @"Down", @"Up", @"Back", @"InstantReplay", @"Info", @"Backspace", @"Search", @"Enter", @"Lit_" ]

@interface RokuService : DeviceService <Launcher, MediaPlayer, MediaControl, KeyControl, TextInputControl>

- (void)sendKeyCode:(RokuKeyCode)keyCode success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
