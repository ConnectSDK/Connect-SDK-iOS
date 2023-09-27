//
//  DiscoveryManager_Private.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-06-16.
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

#import "DiscoveryManager.h"

@class AppStateChangeNotifier;
@class DiscoveryProvider;

NS_ASSUME_NONNULL_BEGIN
@interface DiscoveryManager ()

/// An @c AppStateChangeNotifier that allows to track app state changes.
@property (nonatomic, readonly) AppStateChangeNotifier *appStateChangeNotifier;


/// Initializes the instance with the given @c AppStateChangeNotifier. Using
/// @c nil parameter will create real object.
- (instancetype)initWithAppStateChangeNotifier:(nullable AppStateChangeNotifier *)stateNotifier;

/**
 * Registers a service with the given @c deviceClass and a @c DiscoveryProvider
 * created by the @c providerFactory.
 */
- (void)registerDeviceService:(Class)deviceClass
 withDiscoveryProviderFactory:(DiscoveryProvider *(^)(void))providerFactory;

@end
NS_ASSUME_NONNULL_END
