//
//  OCMStubRecorder+SpectaAsync.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/27/15.
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

#import <OCMock/OCMStubRecorder.h>
#import <Specta/SpectaDSL.h>

NS_ASSUME_NONNULL_BEGIN
@interface OCMStubRecorder (SpectaAsync)

/// Convenience method to call the Specta's @c DoneCallback received from the
/// @c waitUntil() method.
- (id)andDoneWaiting:(DoneCallback)done;

@end
NS_ASSUME_NONNULL_END
