//
// Created by Jeremy White on 6/16/14.
// Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "MultiScreenService.h"
#import "DiscoveryManager.h"
#import "MultiScreenDiscoveryProvider.h"
#import "ConnectError.h"
#import "MultiScreenWebAppSession.h"
#import "ConnectUtil.h"

@implementation MultiScreenService
{
    NSMutableDictionary *_sessions;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
        @"serviceId" : kConnectSDKMultiScreenTVServiceId
    };
}

- (void) setServiceDescription:(ServiceDescription *)serviceDescription
{
    if (!serviceDescription)
        return;

    [super setServiceDescription:serviceDescription];

    _device = [self deviceForId:serviceDescription.UUID];
}

- (MSDevice *) deviceForId:(NSString *)deviceId
{
    if (!deviceId || deviceId.length == 0)
        return nil;

    __block MSDevice *device;

    [[DiscoveryManager sharedManager].discoveryProviders enumerateObjectsUsingBlock:^(DiscoveryProvider *provider, NSUInteger idx, BOOL *stop) {
        if ([provider isKindOfClass:[MultiScreenDiscoveryProvider class]])
        {
            MultiScreenDiscoveryProvider *multiScreenProvider = (MultiScreenDiscoveryProvider *) provider;
            device = multiScreenProvider.devices[deviceId];
            *stop = YES;
        }
    }];

    return device;
}

#pragma mark - DeviceService methods

- (void) updateCapabilities
{
    NSArray *caps = @[
            kWebAppLauncherLaunch,
            kWebAppLauncherLaunchParams,
            kWebAppLauncherJoin,
            kWebAppLauncherConnect,
            kWebAppLauncherDisconnect,
            kWebAppLauncherMessageSend,
            kWebAppLauncherMessageSendJSON,
            kWebAppLauncherMessageReceive,
            kWebAppLauncherMessageReceiveJSON,
            kWebAppLauncherClose
    ];

    self.capabilities = caps;
}

- (void) connect
{
    if (!_device)
    {
        NSError *connectError = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Was unable to find the MSDevice instance for this IP address"];

        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)])
            dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:connectError]; });

        return;
    }

    self.connected = YES;

    _sessions = [NSMutableDictionary new];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) disconnect
{
    self.connected = NO;

    [_sessions enumerateKeysAndObjectsUsingBlock:^(id key, MultiScreenWebAppSession *session, BOOL *stop) {
        if (session.channel && session.channel.isConnected && session.delegate)
            dispatch_on_main(^{ [session.delegate webAppSessionDidDisconnect:session]; });
    }];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (void) closeLaunchSession:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (launchSession.sessionType == LaunchSessionTypeWebApp)
        [self.webAppLauncher closeWebApp:launchSession success:success failure:failure];
    else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find launcher for provided LaunchSession."]);
    }
}

#pragma mark - Web App Launcher

- (id <WebAppLauncher>) webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel) webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:params relaunchIfRunning:YES success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:nil relaunchIfRunning:relaunchIfRunning success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSError *error;

    if (!webAppId || webAppId.length == 0)
        error = [ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app id"];

    if (!self.device)
        error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find a reference to the native device object"];

    if (error)
    {
        if (failure)
            failure(error);

        return;
    }

    if (!params)
        params = @{};

    webAppId = [ConnectUtil urlEncode:webAppId];

    [self.device getApplication:webAppId completionBlock:^(MSApplication *application, NSError *getError) {
        if (getError || !application)
        {
            if (!getError)
                getError = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Experienced an unknown error getting app info, app may not be installed"];

            if (failure)
                failure(getError);
        } else
        {
            [application launchWithOptions:params completionBlock:^(BOOL launchSuccess, NSError *launchError) {
                if (launchSuccess)
                {
                    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
                    launchSession.sessionType = LaunchSessionTypeWebApp;
                    launchSession.service = self;

                    MultiScreenWebAppSession *webAppSession = _sessions[webAppId];

                    if (!webAppSession)
                    {
                        webAppSession = [[MultiScreenWebAppSession alloc] initWithLaunchSession:launchSession service:self];
                        _sessions[webAppId] = webAppSession;
                    }

                    webAppSession.application = application;

                    if (success)
                        success(webAppSession);
                } else
                {
                    if (!launchError)
                        launchError = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Experienced an unknown error launching app"];

                    if (failure)
                        failure(launchError);
                }
            } queue:dispatch_get_main_queue()];
        }
    } queue:dispatch_get_main_queue()];
}

- (void) joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.device getApplication:webAppLaunchSession.appId completionBlock:^(MSApplication *application, NSError *getError) {
        if (getError || !application)
        {
            if (!getError)
                getError = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Experienced an unknown error getting app info, app may not be installed"];

            if (failure)
                failure(getError);
        } else
        {
            MultiScreenWebAppSession *webAppSession = _sessions[webAppLaunchSession.appId];

            if (!webAppSession)
            {
                webAppSession = [[MultiScreenWebAppSession alloc] initWithLaunchSession:webAppLaunchSession service:self];
                _sessions[webAppLaunchSession.appId] = webAppSession;
            }

            webAppSession.application = application;

            [webAppSession joinWithSuccess:success failure:failure];
        }
    } queue:dispatch_get_main_queue()];
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    [self.webAppLauncher joinWebApp:launchSession success:success failure:failure];
}

- (void) closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSError *error;

    if (!launchSession || !launchSession.appId || launchSession.appId.length == 0)
        error = [ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid launch session"];

    if (!self.device)
        error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find a reference to the native device object"];

    if (error)
    {
        if (failure)
            failure(error);

        return;
    }

    [self.device getApplication:launchSession.appId completionBlock:^(MSApplication *application, NSError *getError) {
        if (getError || !application)
        {
            if (!getError)
                getError = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Experienced an unknown error getting app info, app may not be installed"];

            if (failure)
                failure(getError);
        } else
        {
            [application terminateWithCompletionBlock:^(BOOL terminateSuccess, NSError *terminateError) {
                if (terminateSuccess)
                {
                    [_sessions removeObjectForKey:launchSession.appId];

                    if (success)
                        success(nil);
                } else
                {
                    if (!terminateError)
                        terminateError = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Experienced an unknown error terminating app"];

                    if (failure)
                        failure(terminateError);
                }
            } queue:dispatch_get_main_queue()];
        }
    } queue:dispatch_get_main_queue()];
}

@end
