//
//  CastServiceChannel.h
//  Connect SDK
//
//  Created by Jeremy White on 2/20/14.
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
#import <GoogleCast/GoogleCast.h>
#import "Capability.h"
#import "WebAppLauncher.h"

@class CastWebAppSession;

@interface CastServiceChannel : GCKCastChannel

@property (nonatomic, copy) SuccessBlock connectionSuccess;
@property (nonatomic, copy) FailureBlock connectionFailure;

- (instancetype)initWithAppId:(NSString *)appId session:(CastWebAppSession *)session;

@end
