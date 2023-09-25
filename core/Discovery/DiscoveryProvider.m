//
//  DiscoveryProvider.m
//  Connect SDK
//
//  Created by Jeremy White on 12/5/13.
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

#import "DiscoveryProvider.h"

@implementation DiscoveryProvider

- (void)addDeviceFilter:(NSDictionary *)parameters { }
- (void)removeDeviceFilter:(NSDictionary *)parameters { }
- (BOOL)isEmpty { return YES; }

- (void)startDiscovery { }
- (void)stopDiscovery { }

- (void)pauseDiscovery {
    [self stopDiscovery];
}

- (void)resumeDiscovery {
    [self startDiscovery];
}

@end
