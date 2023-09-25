//
//  XMLWriter+ConvenienceMethods.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/16/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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

#import "XMLWriter.h"

@interface XMLWriter (ConvenienceMethods)

- (void)writeElement:(NSString *)elementName withContents:(NSString *)contents;

- (void)writeElement:(NSString *)elementName
       withNamespace:(NSString *)namespace
andContents:(NSString *)contents;

- (void)writeElement:(NSString *)elementName
   withContentsBlock:(void (^)(XMLWriter *writer))writerBlock;

- (void)writeElement:(NSString *)elementName
       withNamespace:(NSString *)namespace
andContentsBlock:(void (^)(XMLWriter *writer))writerBlock;

- (void)writeAttributes:(NSDictionary *)attributes;

@end
