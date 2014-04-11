//
//  DIALService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/13/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "DIALService.h"
#import "ConnectError.h"
#import "XMLReader.h"

@implementation DIALService

- (NSArray *)capabilities
{
    return @[
            kLauncherApp,
            kLauncherAppParams,
            kLauncherAppClose,
            kLauncherAppState
    ];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId":@"DIAL",
             @"ssdp":@{
                     @"filter":@"urn:dial-multiscreen-org:service:dial:1"
                     }
             };
}

- (void)setServiceDescription:(ServiceDescription *)serviceDescription
{
    [super setServiceDescription:serviceDescription];

    NSString *commandPath = [self.serviceDescription.locationResponseHeaders objectForKey:@"Application-URL"];
    self.serviceDescription.commandURL = [NSURL URLWithString:commandPath];
}

- (void) connect
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(ServiceCommand *)command withPayload:(NSDictionary *)payload toURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:6];

    if (payload || [command.HTTPMethod isEqualToString:@"POST"])
    {
        [request setHTTPMethod:@"POST"];

        if (payload)
        {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
            [request addValue:[NSString stringWithFormat:@"%i", (unsigned int) [jsonData length]] forHTTPHeaderField:@"Content-Length"];
            [request addValue:@"text/plain;charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:jsonData];
        } else
        {
            [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];
        }
    } else
    {
        [request setHTTPMethod:command.HTTPMethod];
        [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];
    }

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (connectionError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError(connectionError); });
        } else
        {
            BOOL statusOK = NO;
            NSError *error;
            NSString *locationPath;

            switch ([httpResponse statusCode])
            {
                case 503:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:@"Could not start application"];
                    break;

                case 501:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:@"Was unable to perform the requested action, not supported"];
                    break;

                case 413:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Message body is too long"];
                    break;

                case 404:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find requested application"];
                    break;

                case 201: // CREATED:  application launch success
                    statusOK = YES;
                    locationPath = [httpResponse.allHeaderFields objectForKey:@"Location"];
                    break;

                case 206: // PARTIAL CONTENT: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 205: // RESET CONTENT: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 204: // NO CONTENT: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 203: // NON-AUTHORITATIVE INFORMATION: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 202: // ACCEPTED: not listed in DIAL spec, but don't want to exclude successful 2xx response code
                case 200: // OK: command success
                    statusOK = YES;
                    break;

                default:
                    error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"An unknown error occurred"];
            }

            if (statusOK)
            {
                NSError *xmlError;
                NSDictionary *responseXML = [XMLReader dictionaryForXMLData:data error:&xmlError];

                if (xmlError)
                {
                    if (command.callbackError)
                        command.callbackError(xmlError);
                } else
                {
                    if (command.callbackComplete)
                    {
                        if (locationPath)
                            dispatch_on_main(^{ command.callbackComplete(locationPath); });
                        else
                            dispatch_on_main(^{ command.callbackComplete(responseXML); });
                    }
                }
            } else
            {
                if (command.callbackError)
                    command.callbackError(error);
            }
        }
    }];

    // TODO: need to implement callIds in here
    return 0;
}

#pragma mark - Launcher

- (id <Launcher>)launcher
{
    return self;
}

- (CapabilityPriorityLevel) launcherPriority
{
    return CapabilityPriorityLevelNormal;
}

- (void)launchApp:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApplication:appId withParams:nil success:success failure:failure];
}

- (void)launchApplication:(NSString *)appId withParams:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!appId || [appId isEqualToString:@""])
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid app id"]);

        return;
    }

    AppInfo *appInfo = [AppInfo appInfoForId:appId];
    appInfo.name = appId;

    [self launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchAppWithInfo:(AppInfo *)appInfo success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchAppWithInfo:appInfo params:nil success:success failure:failure];
}

- (void)launchAppWithInfo:(AppInfo *)appInfo params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!appInfo || !appInfo.id)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid AppInfo object"]);

        return;
    }

    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:appInfo.id];

    [self getAppState:launchSession success:^(BOOL running, BOOL visible)
    {
        if (running)
        {
            [self getApplicationInfo:launchSession.appId success:^(id responseObject)
            {
                NSString *resourceName = [[[responseObject objectForKey:@"service"] objectForKey:@"link"] objectForKey:@"text"];

                if (!resourceName || [resourceName isEqualToString:@""])
                    resourceName = @"run";

                [self launchApplicationWithInfo:appInfo params:params resourceName:resourceName success:success failure:failure];
            } failure:failure];
        } else
        {
            [self launchApplicationWithInfo:appInfo params:params resourceName:nil success:success failure:failure];
        }

    } failure:failure];
}

- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchNetflix:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params;

    if (contentId && ![contentId isEqualToString:@""])
        params = @{ @"v" : contentId }; // TODO: verify this works

    AppInfo *appInfo = [AppInfo appInfoForId:@"Netflix"];
    appInfo.name = appInfo.id;

    [self.launcher launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchYouTube:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params;

    if (contentId && ![contentId isEqualToString:@""])
        params = @{ @"v" : contentId }; // TODO: verify this works

    AppInfo *appInfo = [AppInfo appInfoForId:@"YouTube"];
    appInfo.name = appInfo.id;

    [self.launcher launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (ServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)getAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self getApplicationInfo:launchSession.appId success:^(id responseObject)
    {
        NSString *state = [[[responseObject objectForKey:@"service"] objectForKey:@"state"] objectForKey:@"text"];

        BOOL running = [state isEqualToString:@"running"];
        BOOL visible = [state isEqualToString:@"running"];

        if (success)
            success(running, visible);
    } failure:failure];
}

- (ServiceSubscription *)subscribeAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)closeApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession || !launchSession.sessionId)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid launch session"]);

        return;
    }

    NSURL *commandURL = [NSURL URLWithString:launchSession.sessionId];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"DELETE";
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getAppListWithSuccess:(AppListSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Helper methods

- (void) hasApplication:(NSString *)appId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!appId || [appId isEqualToString:@""])
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid app id"]);

        return;
    }

    NSString *commandPath = [NSString pathWithComponents:@[
            self.serviceDescription.commandURL.absoluteString,
            appId
    ]];

    NSURL *commandURL = [NSURL URLWithString:commandPath];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void) getApplicationInfo:(NSString *)appId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!appId || [appId isEqualToString:@""])
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid app id"]);

        return;
    }

    NSString *commandPath = [NSString pathWithComponents:@[
            self.serviceDescription.commandURL.absoluteString,
            appId
    ]];

    NSURL *commandURL = [NSURL URLWithString:commandPath];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)launchApplicationWithInfo:(AppInfo *)appInfo params:(NSDictionary *)params resourceName:(NSString *)resourceName success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandPath;

    if (resourceName && ![resourceName isEqualToString:@""])
        commandPath = [NSString pathWithComponents:@[self.serviceDescription.commandURL.absoluteString, appInfo.id, resourceName]];
    else
        commandPath = [NSString pathWithComponents:@[self.serviceDescription.commandURL.absoluteString, appInfo.id]];

    NSURL *statusCommandURL = [NSURL URLWithString:commandPath];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:statusCommandURL payload:params];
    command.HTTPMethod = @"POST";
    command.callbackComplete = ^(NSString *locationPath)
    {
        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:appInfo.id];
        launchSession.name = appInfo.name;
        launchSession.sessionId = locationPath;
        launchSession.sessionType = LaunchSessionTypeApp;
        launchSession.service = self;

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

@end
