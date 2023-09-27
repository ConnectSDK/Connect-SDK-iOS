//
//  WebOSTVService+LGCast.h
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

#import "ConnectSDK.h"
#import "WebOSTVService.h"

NS_ASSUME_NONNULL_BEGIN

@interface WebOSTVService (LGCast)

- (ServiceSubscription *)subscribeCommandWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;
- (ServiceSubscription *)subscribePowerStateWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

- (void)sendConnectWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendGetParameterWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendSetParameterWithService:(NSString *)service sourceInfo:(NSDictionary *)sourceInfo deviceInfo:(NSDictionary *)deviceInfo success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendGetParameterResponseWithService:(NSString *)service values:(NSDictionary *)values success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendSetParameterResponseWithService:(NSString *)service values:(NSDictionary *)values success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendKeepAliveWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void)sendTeardownWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure;

@end

NS_ASSUME_NONNULL_END
