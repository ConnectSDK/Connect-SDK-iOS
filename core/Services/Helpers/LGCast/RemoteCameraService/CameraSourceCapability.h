//
//  CameraSourceCapability.h
//  LGCast
//
//  Copyright (c) 2022 LG Electronics. All rights reserved.
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

#ifndef CameraSourceCapability_h
#define CameraSourceCapability_h

#import <Foundation/Foundation.h>
#import <LGCast/LGCast-Swift.h>

@interface CameraSourceCapability : NSObject
 
@property NSArray<LGCastCameraResolutionInfo *> *resolutions;

- (void)setSecurityKeys:(NSArray<LGCastSecurityKey *> *)keys;
- (NSDictionary *)toNSDictionary;

@end

#endif /* CameraSourceCapability_h */
