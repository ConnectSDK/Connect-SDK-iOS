//
//  DIALService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/13/13.
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

#import "DIALService.h"
#import "ConnectError.h"
#import "CTXMLReader.h"
#import "DeviceServiceReachability.h"
#import "CTGuid.h"

#import "NSObject+FeatureNotSupported_Private.h"

static NSMutableArray *registeredApps = nil;

@interface DIALService () <DeviceServiceReachabilityDelegate>

@end

@implementation DIALService
{
    DeviceServiceReachability *_serviceReachability;
}

+ (void) initialize
{
    registeredApps = [NSMutableArray arrayWithArray:@[
            @"YouTube",
            @"Netflix",
            @"Amazon"
    ]];
}

- (void) commonInit
{
    [self addCapabilities:@[
            kLauncherApp,
            kLauncherAppParams,
            kLauncherAppClose,
            kLauncherAppState
    ]];
}

- (instancetype) init
{
    self = [super init];

    if (self)
        [self commonInit];

    return self;
}

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super initWithServiceConfig:serviceConfig];

    if (self)
        [self commonInit];

    return self;
}

+ (void) registerApp:(NSString *)appId
{
    if (![registeredApps containsObject:appId])
        [registeredApps addObject:appId];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId":kConnectSDKDIALServiceId,
             @"ssdp":@{
                     @"filter":@"urn:dial-multiscreen-org:service:dial:1"
                     }
             };
}

- (void)setServiceDescription:(ServiceDescription *)serviceDescription
{
    [super setServiceDescription:serviceDescription];

    if (self.serviceDescription.locationResponseHeaders)
    {
        NSString *commandPath = [self.serviceDescription.locationResponseHeaders objectForKey:@"Application-URL"];
        self.serviceDescription.commandURL = [NSURL URLWithString:commandPath];
    }
    
    [self probeForAppSupport];
}

- (void) updateCapabilities
{
    NSArray *capabilities = @[
            kLauncherApp,
            kLauncherAppParams,
            kLauncherAppClose,
            kLauncherAppState
    ];

    [self setCapabilities:capabilities];
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
//    NSString *targetPath = [NSString stringWithFormat:@"http://%@:%@/", self.serviceDescription.address, @(self.serviceDescription.port)];
//    NSURL *targetURL = [NSURL URLWithString:targetPath];

    _serviceReachability = [DeviceServiceReachability reachabilityWithTargetURL:self.serviceDescription.commandURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    self.connected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) disconnect
{
    self.connected = NO;

    [_serviceReachability stop];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (void) didLoseReachability:(DeviceServiceReachability *)reachability
{
    if (self.connected)
        [self disconnect];
    else
        [_serviceReachability stop];
}

- (void) probeForAppSupport
{
    [registeredApps enumerateObjectsUsingBlock:^(NSString *appName, NSUInteger idx, BOOL *stop)
    {
        [self hasApplication:appName success:^(id responseObject)
        {
            NSString *capability = [NSString stringWithFormat:@"Launcher.%@", appName];
            NSString *capabilityParams = [NSString stringWithFormat:@"Launcher.%@.Params", appName];
            
            [self addCapabilities:@[capability, capabilityParams]];
        } failure:nil];
    }];
}

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(ServiceCommand *)command withPayload:(id)payload toURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:6];

    if (payload || [command.HTTPMethod isEqualToString:@"POST"])
    {
        [request setHTTPMethod:@"POST"];

        if (payload)
        {
            NSData *payloadData;

            if ([payload isKindOfClass:[NSString class]])
            {
                NSString *payloadString = (NSString *)payload;
                payloadData = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([payload isKindOfClass:[NSDictionary class]])
                payloadData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

            if (payloadData == nil)
            {
                if (command.callbackError)
                    command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Unknown error preparing message to send"]);

                return -1;
            }

            [request addValue:[NSString stringWithFormat:@"%i", (unsigned int) [payloadData length]] forHTTPHeaderField:@"Content-Length"];
            [request addValue:@"text/plain;charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:payloadData];

            DLog(@"[OUT] : %@ \n %@", [request allHTTPHeaderFields], payload);
        } else
        {
            [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];
        }
    } else
    {
        [request setHTTPMethod:command.HTTPMethod];
        [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];

        DLog(@"[OUT] : %@", [request allHTTPHeaderFields]);
    }

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        DLog(@"[IN] : %@", [httpResponse allHeaderFields]);

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
                NSDictionary *responseXML = [CTXMLReader dictionaryForXMLData:data error:&xmlError];

                DLog(@"[IN] : %@", responseXML);

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

                if (!resourceName)
                    resourceName = [[[responseObject objectForKey:@"service"] objectForKey:@"atom:link"] objectForKey:@"rel"];

                [self launchApplicationWithInfo:appInfo params:params resourceName:resourceName success:success failure:failure];
            } failure:failure];
        } else
        {
            [self launchApplicationWithInfo:appInfo params:params resourceName:nil success:success failure:failure];
        }

    } failure:failure];
}

- (void) launchAppStore:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
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
    [self.launcher launchYouTube:contentId startTime:0.0 success:success failure:failure];
}

- (void) launchYouTube:(NSString *)contentId startTime:(float)startTime success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *params;

    if (contentId && contentId.length > 0) {
        if (startTime < 0.0)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Start time may not be negative"]);

            return;
        }

        // YouTube on some platforms requires a pairing code, which may be a random string
        NSString *pairingCode = [[CTGuid randomGuid] stringValue];

        params = [NSString stringWithFormat:@"pairingCode=%@&v=%@&t=%.1f", pairingCode, contentId, startTime];
    }

    AppInfo *appInfo = [AppInfo appInfoForId:@"YouTube"];
    appInfo.name = appInfo.id;
    
    [self.launcher launchAppWithInfo:appInfo params:(id)params success:^(LaunchSession *launchSession)
    {
        if (success)
            success(launchSession);
    } failure:^(NSError *error)
    {
        if (failure)
            failure(error);
    }];
}

- (ServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
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
    return [self sendNotSupportedFailure:failure];
}

- (void)closeApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession || !launchSession.sessionId)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid launch session"]);

        return;
    }
    
    NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@", self.serviceDescription.commandURL.host, self.serviceDescription.commandURL.port];
    if ([launchSession.sessionId hasPrefix:@"http://"] || [launchSession.sessionId hasPrefix:@"https://"])
      commandPath = launchSession.sessionId;//chromecast returns full url
    else
      commandPath = [commandPath stringByAppendingPathComponent:launchSession.sessionId];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"DELETE";
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getAppListWithSuccess:(AppListSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)getRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
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

    NSString *commandPath = self.serviceDescription.commandURL.absoluteString;
    commandPath = [commandPath stringByAppendingPathComponent:appId];

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

    if (resourceName && resourceName.length > 0)
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
