//
//  CameraSourceCapability.m
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

#import "CameraSourceCapability.h"
@interface CameraSourceCapability()
    @property NSArray<LGCastSecurityKey *> *masterKeys;
@end

@implementation CameraSourceCapability

NSString *const kRCKeyCrypto = @"crypto";
NSString *const kRCKeyCryptoMki = @"mki";
NSString *const kRCKeyCryptokey = @"key";

NSString *const kRCKeyPreviewSize = @"previewSize";
NSString *const kRCKeyPreviewSizeW = @"w";
NSString *const kRCKeyPreviewSizeH = @"h";

- (void)setSecurityKeys:(NSArray<LGCastSecurityKey *> *)keys {
    _masterKeys = keys;
}

- (NSDictionary *)toNSDictionary {
    NSMutableArray<NSDictionary *> *cryptoSpec = [[NSMutableArray alloc] init];
    
    for (LGCastSecurityKey *key in _masterKeys) {
        [cryptoSpec addObject:@{
            kRCKeyCryptoMki: key.mki,
            kRCKeyCryptokey: key.masterKey
        }];
    }
   
    NSMutableArray<NSDictionary *> *previewSize = [[NSMutableArray alloc] init];
    
    for (LGCastCameraResolutionInfo *resolution in _resolutions) {
        [previewSize addObject:@{
            kRCKeyPreviewSizeW: [NSNumber numberWithLong:resolution.width],
            kRCKeyPreviewSizeH: [NSNumber numberWithLong:resolution.height]
        }];
    }
    
    return @{
        kRCKeyCrypto: cryptoSpec,
        kRCKeyPreviewSize: previewSize
    };
}

@end
