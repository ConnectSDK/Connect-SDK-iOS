//
//  ServiceAsychCommand.m
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/23/13.
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

#import "ServiceAsyncCommand.h"

@implementation ServiceAsyncCommand

- (instancetype) initWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    self = [super initWithDelegate:delegate target:target payload:payload];
    return self;
}

+ (instancetype) asyncWithDelegate:(id <ServiceCommandDelegate>)delegate target:(NSURL *)target payload:(id)payload
{
    return [[ServiceAsyncCommand alloc] initWithDelegate:delegate target:target payload:payload];;
}

- (void) send
{
    if ([self.delegate respondsToSelector:@selector(sendAsync:withPayload:toURL:)])
        [self.delegate sendAsync:self withPayload:self.payload toURL:self.target];
}

@end
