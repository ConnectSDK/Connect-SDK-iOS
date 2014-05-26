//
// Created by Jeremy White on 4/24/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "AirPlayWebAppSession.h"
#import "ConnectError.h"
#import "ConnectUtil.h"


@interface AirPlayWebAppSession () <ServiceCommandDelegate>

@end

@implementation AirPlayWebAppSession
{
    ServiceSubscription *_webAppStatusSubscription;
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    {
        if (subscription == _webAppStatusSubscription)
        {
            [[_webAppStatusSubscription successCalls] removeAllObjects];
            [[_webAppStatusSubscription failureCalls] removeAllObjects];
            [_webAppStatusSubscription setIsSubscribed:NO];
            _webAppStatusSubscription = nil;
        }
    }

    return -1;
}

- (ServiceSubscription *) subscribeWebAppStatus:(WebAppStatusBlock)success failure:(FailureBlock)failure
{
    if (!_webAppStatusSubscription)
        _webAppStatusSubscription = [ServiceSubscription subscriptionWithDelegate:self target:nil payload:nil callId:-1];

    [_webAppStatusSubscription addSuccess:success];
    [_webAppStatusSubscription addFailure:failure];
    [_webAppStatusSubscription setIsSubscribed:YES];

    return _webAppStatusSubscription;
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service.webAppLauncher joinWebApp:self.launchSession success:success failure:failure];
}

- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.service closeLaunchSession:self.launchSession success:success failure:failure];
}

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (success)
        success(nil);
}

- (void) disconnectFromWebApp
{
    [self.service disconnectFromWebApp];
}

- (void) sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMessage:message success:success failure:failure];
}

- (void) sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMessage:message success:success failure:failure];
}

- (void) sendMessage:(id)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!message)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid argument"]);
    }

    NSDictionary *messageDictionary = @{
            @"data" : message
    };

    NSError *error;
    NSData *messageData = [NSJSONSerialization dataWithJSONObject:messageDictionary options:0 error:&error];

    if (error || !messageData)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not parse message into sendable format"]);
    } else
    {
        NSString *messageString = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
        NSString *commandString = [NSString stringWithFormat:@"window.connectManager.handleMessage(%@)", messageString];

        [self.service.webAppWebView stringByEvaluatingJavaScriptFromString:commandString];

        if (success)
            success(nil);
    }
}

@end
