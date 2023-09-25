//
//  WebOSTVService+LGCast.m
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

#import "WebOSTVService+LGCast.h"
#import "ServiceAsyncCommand.h"
#import "WebOSTVServiceSocketClient.h"
#import <LGCast/LGCast-Swift.h>

@implementation WebOSTVService (LGCast)

NSString *const kCommandKey = @"cmd";
NSString *const kSubscribeKey = @"subscribe";
NSString *const kServiceKey = @"service";
NSString *const kClientKeyKey = @"clientKey";
NSString *const kDeviceInfoKey = @"deviceInfo";

NSString *const kCommandConnect = @"CONNECT";
NSString *const kCommandGetParameter = @"GET_PARAMETER";
NSString *const kCommandSetParameter = @"SET_PARAMETER";
NSString *const kCommandGetParameterResponse = @"GET_PARAMETER_RESPONSE";
NSString *const kCommandSetParameterResponse = @"SET_PARAMETER_RESPONSE";
NSString *const kCommandKeepAlive = @"KEEPALIVE";
NSString *const kCommandTeardown = @"TEARDOWN";

- (ServiceSubscription *)subscribeCommandWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/getCommand"];
    NSDictionary *payload = @{ kSubscribeKey : @YES };

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:success failure:failure];

    return subscription;
}

- (ServiceSubscription *)subscribePowerStateWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure {
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tvpower/power/getPowerState"];
    NSDictionary *payload = @{ kSubscribeKey : @YES };

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:success failure:failure];
    
    return subscription;
}

- (void)sendConnectWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendCommandWithService:service command:kCommandConnect parameter:nil successBlock:success failureBlock:failure];
}

- (void)sendGetParameterWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendCommandWithService:service command:kCommandGetParameter parameter:nil successBlock:success failureBlock:failure];
}

- (void)sendSetParameterWithService:(NSString *)service sourceInfo:(NSDictionary *)sourceInfo deviceInfo:(NSDictionary *)deviceInfo success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *param;
    
    if (deviceInfo == nil) {
        param = @{ service: sourceInfo };
    } else {
        param = @{
            service: sourceInfo,
            kDeviceInfoKey: deviceInfo
        };
    }
    
    [self sendCommandWithService:service command:kCommandSetParameter parameter:param successBlock:success failureBlock:failure];
}

- (void)sendGetParameterResponseWithService:(NSString *)service values:(NSDictionary *)values success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *param = @{
        service: values
    };
    
    [self sendCommandWithService:service command:kCommandGetParameterResponse parameter:param successBlock:success failureBlock:failure];
}

- (void)sendSetParameterResponseWithService:(NSString *)service values:(NSDictionary *)values success:(SuccessBlock)success failure:(FailureBlock)failure {
    NSDictionary *param = @{
        service: values
    };
    
    [self sendCommandWithService:service command:kCommandSetParameterResponse parameter:param successBlock:success failureBlock:failure];
}

- (void)sendKeepAliveWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendCommandWithService:service command:kCommandKeepAlive parameter:nil successBlock:success failureBlock:failure];
}

- (void)sendTeardownWithService:(NSString *)service success:(SuccessBlock)success failure:(FailureBlock)failure {
    [self sendCommandWithService:service command:kCommandTeardown parameter:nil successBlock:success failureBlock:failure];
}

- (void)sendCommandWithService:(NSString *)service command:(NSString *)command parameter:(NSDictionary *)parameter successBlock:(SuccessBlock)success failureBlock:(FailureBlock)failure {
    if (self.webOSTVServiceConfig == nil || self.webOSTVServiceConfig.clientKey == nil) {
        [Log errorLGCast:@"client key is nil"];
        return;
    }
    
    NSURL *url = [NSURL URLWithString:@"ssap://com.webos.service.appcasting/sendCommand"];
    NSDictionary *defaultPayload = @{
        kCommandKey: command,
        kClientKeyKey: self.webOSTVServiceConfig.clientKey,
        kServiceKey: service
    };

    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:defaultPayload];
    [payload addEntriesFromDictionary: parameter];
    
    ServiceCommand *serviceCommand = [ServiceAsyncCommand commandWithDelegate:self.socket target:url payload:payload];
    serviceCommand.callbackComplete = success;
    serviceCommand.callbackError = failure;
    [serviceCommand send];
}

@end
