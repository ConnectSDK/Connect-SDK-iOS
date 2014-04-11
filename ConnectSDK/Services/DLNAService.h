//
//  DLNAService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/13/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <ConnectSDK/ConnectSDK.h>
#import "Launcher.h"
#import "MediaControl.h"

@interface DLNAService : DeviceService <MediaPlayer, MediaControl>

@end
