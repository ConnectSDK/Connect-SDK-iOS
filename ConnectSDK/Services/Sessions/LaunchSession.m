//
// Created by Jeremy White on 1/28/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "LaunchSession.h"
#import "ConnectError.h"
#import "DeviceService.h"

@implementation LaunchSession


+ (LaunchSession *) launchSessionForAppId:(NSString *)appId
{
    LaunchSession *launchSession = [[LaunchSession alloc] init];
    launchSession.appId = appId;

    return launchSession;
}

+ (LaunchSession *) launchSessionFromJSONObject:(NSDictionary *)json
{
    return [[LaunchSession alloc] initWithJSONObject:json];
}

- (instancetype) initWithJSONObject:(NSDictionary*)json
{
    self = [super init];
    
    if (self) {
        self.appId = [json objectForKey:@"appId"];
        self.sessionId = [json objectForKey:@"sessionId"];
        self.name = [json objectForKey:@"name"];
        self.sessionType = (LaunchSessionType) [[json objectForKey:@"sessionType"] integerValue];
        self.rawData = [json objectForKey:@"rawData"];
    }
    
    return self;
}

- (NSDictionary *) toJSONObject
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    if (self.appId) [json setObject:self.appId forKey:@"appId"];
    if (self.sessionId) [json setObject:self.sessionId forKey:@"sessionId"];
    if (self.name) [json setObject:self.name forKey:@"name"];
    if (self.sessionType) [json setObject:@(self.sessionType) forKey:@"sessionType"];
    if (self.service) [json setObject:[self.service serviceName] forKey:@"serviceName"];

    if (self.rawData)
    {
        if ([self.rawData isKindOfClass:[NSDictionary class]] ||
                [self.rawData isKindOfClass:[NSArray class]] ||
                [self.rawData isKindOfClass:[NSString class]])
           [json setObject:self.rawData forKey:@"rawData"];
    }

    return json;
}

- (BOOL)isEqual:(LaunchSession *)launchSession
{
    return [launchSession.appId isEqualToString:self.appId] && [launchSession.sessionId isEqualToString:self.sessionId];
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!self.service)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"This LaunchSession has no DeviceService reference"]);

        return;
    }

    [self.service closeLaunchSession:self success:success failure:failure];
}

@end
