//
//  WebOSService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#import "WebOSTVService.h"
#import "ConnectError.h"
#import "DiscoveryManager.h"
#import "ServiceAsyncCommand.h"
#import "WebOSWebAppSession.h"
#import "WebOSTVServiceSocketClient.h"

#define kKeyboardEnter @"\x1b ENTER \x1b"
#define kKeyboardDelete @"\x1b DELETE \x1b"

@interface WebOSTVService () <UIAlertViewDelegate, WebOSTVServiceSocketClientDelegate>
{
    NSArray *_permissions;

    NSMutableDictionary *_webAppSessions;
    NSMutableDictionary *_appToAppIdMappings;

    NSTimer *_pairingTimer;
    UIAlertView *_pairingAlert;

    NSMutableArray *_keyboardQueue;
    BOOL _keyboardQueueProcessing;

    BOOL _mouseInit;
}

@end

@implementation WebOSTVService

@synthesize serviceDescription = _serviceDescription;

#pragma mark - Setup

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super init];

    if (self)
    {
        [self setServiceConfig:serviceConfig];
    }

    return self;
}

#pragma mark - Inherited methods

- (void) setServiceConfig:(ServiceConfig *)serviceConfig
{
    if ([serviceConfig isKindOfClass:[WebOSTVServiceConfig class]])
    {
        if (self.serviceConfig.clientKey && !((WebOSTVServiceConfig *) serviceConfig).clientKey)
            NSAssert(!self.serviceConfig.clientKey, @"Losing important data!");

        [super setServiceConfig:(WebOSTVServiceConfig *) serviceConfig];
    } else
    {
        NSAssert(!self.serviceConfig.clientKey, @"Losing important data!");

        [super setServiceConfig:[[WebOSTVServiceConfig alloc] initWithServiceConfig:serviceConfig]];
    }
}

- (void) setServiceDescription:(ServiceDescription *)serviceDescription
{
    _serviceDescription = serviceDescription;

    if (!self.serviceConfig.UUID)
        self.serviceConfig.UUID = serviceDescription.UUID;

    if (!_serviceDescription.locationResponseHeaders)
        return;

    NSString *serverInfo = [_serviceDescription.locationResponseHeaders objectForKey:@"Server"];
    NSString *systemOS = [[serverInfo componentsSeparatedByString:@" "] firstObject];
    NSString *systemVersion = [[systemOS componentsSeparatedByString:@"/"] lastObject];

    _serviceDescription.version = systemVersion;

    [self updateCapabilities];
}

- (DeviceService *)dlnaService
{
    NSDictionary *allDevices = [[DiscoveryManager sharedManager] allDevices];
    ConnectableDevice *device;
    DeviceService *service;

    if (allDevices && allDevices.count > 0)
        device = [allDevices objectForKey:self.serviceDescription.address];

    if (device)
        service = [device serviceWithName:@"DLNA"];

    return service;
}

- (void) updateCapabilities
{
    NSArray *capabilities = [NSArray array];

    if ([DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn)
    {
        capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                kKeyControlSendKeyCode,
                kKeyControlUp,
                kKeyControlDown,
                kKeyControlLeft,
                kKeyControlRight,
                kKeyControlHome,
                kKeyControlBack,
                kKeyControlOK
        ]];

        capabilities = [capabilities arrayByAddingObjectsFromArray:kMouseControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kTextInputControlCapabilities];
        capabilities = [capabilities arrayByAddingObject:kPowerControlOff];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kLauncherCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kTVControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kExternalInputControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kToastControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaControlCapabilities];
    } else
    {
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                kLauncherApp,
                kLauncherAppParams,
                kLauncherAppStore,
                kLauncherAppStoreParams
                kLauncherAppClose,
                kLauncherBrowser,
                kLauncherBrowserParams,
                kLauncherHulu,
                kLauncherNetflix,
                kLauncherNetflixParams,
                kLauncherYouTube,
                kLauncherYouTubeParams,
                kLauncherAppState,
                kLauncherAppStateSubscribe
        ]];
    }

    if (_serviceDescription && _serviceDescription.version)
    {
        if ([_serviceDescription.version rangeOfString:@"4.0.0"].location == NSNotFound && [_serviceDescription.version rangeOfString:@"4.0.1"].location == NSNotFound)
        {
            capabilities = [capabilities arrayByAddingObjectsFromArray:kWebAppLauncherCapabilities];
            capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaControlCapabilities];
        } else
        {
            capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                    kWebAppLauncherLaunch,
                    kWebAppLauncherLaunchParams,

                    kMediaControlPlay,
                    kMediaControlPause,
                    kMediaControlStop,
                    kMediaControlSeek,
                    kMediaControlPosition,
                    kMediaControlDuration,
                    kMediaControlPlayState,

                    kWebAppLauncherClose
            ]];
        }
    }

    [self setCapabilities:capabilities];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId": kConnectSDKWebOSTVServiceId,
             @"ssdp":@{
                     @"filter":@"urn:lge-com:service:webos-second-screen:1"
                  }
             };
}

- (BOOL) isConnectable
{
    return YES;
}

- (BOOL) connected
{
    if ([DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn)
        return self.socket.connected && self.serviceConfig.clientKey != nil;
    else
        return self.socket.connected;
}

- (void) connect
{
    if (!self.socket)
    {
        _socket = [[WebOSTVServiceSocketClient alloc] initWithService:self];
        _socket.delegate = self;
    }

    if (!self.connected)
        [self.socket connect];
}

- (void) disconnect
{
    if (self.connected)
        [self disconnectWithError:nil];
}

- (void) disconnectWithError:(NSError *)error
{
    if (self.connected)
        [self.socket disconnectWithError:error];

    [_webAppSessions enumerateKeysAndObjectsUsingBlock:^(id key, WebOSWebAppSession *session, BOOL *stop) {
        [session disconnectFromWebApp];
    }];

    _webAppSessions = [NSMutableDictionary new];
}

#pragma mark - Initial connection & pairing

- (BOOL) requiresPairing
{
    return [DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn;
}

#pragma mark - Paring alert

-(void) showAlert
{
    NSString *title = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Title" value:@"Pairing with device" table:@"ConnectSDK"];
    NSString *message = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Request" value:@"Please confirm the connection on your device" table:@"ConnectSDK"];
    NSString *ok = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_OK" value:@"OK" table:@"ConnectSDK"];
    NSString *cancel = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Cancel" value:@"Cancel" table:@"ConnectSDK"];
    
    _pairingAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil];
    dispatch_on_main(^{ [_pairingAlert show]; });
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        [self disconnect];
}

#pragma - WebOSTVServiceSocketClientDelegate

- (void) socketWillRegister:(WebOSTVServiceSocketClient *)socket
{
    _pairingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showAlert) userInfo:nil repeats:NO];
}

- (void) socket:(WebOSTVServiceSocketClient *)socket registrationFailed:(NSError *)error
{
    if (_pairingAlert && _pairingAlert.isVisible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:0 animated:NO]; });

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:pairingFailedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self pairingFailedWithError:error]; });
}

- (void) socketDidConnect:(WebOSTVServiceSocketClient *)socket
{
    [_pairingTimer invalidate];

    if (_pairingAlert && _pairingAlert.visible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:1 animated:YES]; });

    if ([self.delegate respondsToSelector:@selector(deviceServicePairingSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServicePairingSuccess:self]; });

    if ([self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) socket:(WebOSTVServiceSocketClient *)socket didFailWithError:(NSError *)error
{
    if (_pairingAlert && _pairingAlert.visible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:0 animated:YES]; });

    if ([self.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:error]; });
}

- (void) socket:(WebOSTVServiceSocketClient *)socket didCloseWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

#pragma mark - Helper methods

- (NSArray *)permissions
{
    if (_permissions)
        return _permissions;

    NSMutableArray *defaultPermissions = [[NSMutableArray alloc] init];
    [defaultPermissions addObjectsFromArray:kWebOSTVServiceOpenPermissions];

    if ([DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn)
    {
        [defaultPermissions addObjectsFromArray:kWebOSTVServiceProtectedPermissions];
        [defaultPermissions addObjectsFromArray:kWebOSTVServicePersonalActivityPermissions];
    }

    return [NSArray arrayWithArray:defaultPermissions];
}

- (void)setPermissions:(NSArray *)permissions
{
    _permissions = permissions;

    if (self.serviceConfig.clientKey)
    {
        self.serviceConfig.clientKey = nil;

        if (self.connected)
        {
            NSError *error = [ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Permissions changed -- you will need to re-pair to the TV."];
            [self disconnectWithError:error];
        }
    }
}

+ (ChannelInfo *)channelInfoFromDictionary:(NSDictionary *)info
{
    ChannelInfo *channelInfo = [[ChannelInfo alloc] init];
    channelInfo.id = [info objectForKey:@"channelId"];
    channelInfo.name = [info objectForKey:@"channelName"];
    channelInfo.number = [info objectForKey:@"channelNumber"];
    channelInfo.majorNumber = [[info objectForKey:@"majorNumber"] intValue];
    channelInfo.minorNumber = [[info objectForKey:@"minorNumber"] intValue];
    channelInfo.rawData = [info copy];

    return channelInfo;
}

+ (AppInfo *)appInfoFromDictionary:(NSDictionary *)info
{
    AppInfo *appInfo = [[AppInfo alloc] init];
    appInfo.name = [info objectForKey:@"title"];
    appInfo.id = [info objectForKey:@"id"];
    appInfo.rawData = [info copy];

    return appInfo;
}

+ (ExternalInputInfo *)externalInputInfoFromDictionary:(NSDictionary *)info
{
    ExternalInputInfo *externalInputInfo = [[ExternalInputInfo alloc] init];
    externalInputInfo.name = [info objectForKey:@"label"];
    externalInputInfo.id = [info objectForKey:@"id"];
    externalInputInfo.connected = [[info objectForKey:@"connected"] boolValue];
    externalInputInfo.iconURL = [NSURL URLWithString:[info objectForKey:@"icon"]];
    externalInputInfo.rawData = [info copy];

    return externalInputInfo;
}

#pragma mark - Launcher

- (id <Launcher>)launcher
{
    return self;
}

- (CapabilityPriorityLevel) launcherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getAppListWithSuccess:(AppListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/listApps"];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSArray *foundApps = [responseDic objectForKey:@"apps"];
        NSMutableArray *appList = [[NSMutableArray alloc] init];

        [foundApps enumerateObjectsUsingBlock:^(NSDictionary *appInfo, NSUInteger idx, BOOL *stop)
        {
            [appList addObject:[WebOSTVService appInfoFromDictionary:appInfo]];
        }];

        if (success)
            success(appList);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchApp:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApplication:appId withParams:nil success:success failure:failure];
}

- (void)launchApplication:(NSString *)appId withParams:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/launch"];
    
    NSMutableDictionary *payload = [NSMutableDictionary new];

    [payload setValue:appId forKey:@"id"];

    if (params) {
        [payload setValue:params forKey:@"params"];

        NSString *contentId = [params objectForKey:@"contentId"];

        if (contentId)
            [payload setValue:contentId forKey:@"contentId"];
    }

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:appId];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeApp;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchAppWithInfo:(AppInfo *)appInfo success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApp:appInfo.id success:success failure:failure];
}

- (void)launchAppWithInfo:(AppInfo *)appInfo params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApplication:appInfo.id withParams:params success:success failure:failure];
}

- (void) launchAppStore:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    AppInfo *appInfo = [AppInfo appInfoForId:@"com.webos.app.discovery"];
    appInfo.name = @"LG Store";

    NSDictionary *params;

    if (appId && appId.length > 0)
    {
        NSString *query = [NSString stringWithFormat:@"category/GAME_APPS/%@", appId];
        params = @{ @"query" : query };
    }

    [self launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/open"];
    NSDictionary *params = @{ @"target" : target.absoluteString };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:URL payload:params];
    command.callbackComplete = ^(NSDictionary * responseObject)
    {
        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:[responseObject objectForKey:@"id"]];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeApp;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params = @{ @"hulu" : contentId };
    
    [self launchApplication:@"hulu" withParams:params success:success failure:failure];
}

- (void)launchNetflix:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *netflixContentId = [NSString stringWithFormat:@"m=http%%3A%%2F%%2Fapi.netflix.com%%2Fcatalog%%2Ftitles%%2Fmovies%%2F%@&source_type=4", contentId];

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:netflixContentId forKey:@"contentId"];

    [self launchApplication:@"netflix" withParams:params success:success failure:failure];
}

- (void)launchYouTube:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params = @{ @"contentId" : contentId };
    
    [self launchApplication:@"youtube.leanback.v4" withParams:params success:success failure:failure];
}

- (void) connectToApp:(NSString *)appId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:appId];
    launchSession.service = self;
    launchSession.sessionType = LaunchSessionTypeApp;

    WebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:launchSession];

    [self connectToApp:webAppSession joinOnly:NO success:^(id responseObject)
    {
        if (success)
            success(webAppSession);
    } failure:failure];
}

- (void) joinApp:(NSString *)appId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:appId];
    launchSession.service = self;
    launchSession.sessionType = LaunchSessionTypeApp;

    WebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:launchSession];

    [self connectToApp:webAppSession joinOnly:YES success:^(id responseObject)
    {
        if (success)
            success(webAppSession);
    } failure:failure];
}

- (void) connectToApp:(WebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connectToWebApp:webAppSession joinOnly:joinOnly success:success failure:failure];
}

- (ServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/getForegroundAppInfo"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        AppInfo *appInfo = [[AppInfo alloc] init];
        appInfo.id = [responseObject objectForKey:@"appId"];
        appInfo.rawData = [responseObject copy];

        if (success)
            success(appInfo);
    } failure:failure];

    return subscription;
}

- (void)getRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/getForegroundAppInfo"];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        AppInfo *appInfo = [[AppInfo alloc] init];
        appInfo.id = [responseObject objectForKey:@"appId"];
        appInfo.name = [responseObject objectForKey:@"appName"];
        appInfo.rawData = [responseObject copy];

        if (success)
            success(appInfo);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/getAppState"];

    NSMutableDictionary *params = [NSMutableDictionary new];
    if (launchSession && launchSession.appId) [params setValue:launchSession.appId forKey:@"appId"];
    if (launchSession && launchSession.sessionId) [params setValue:launchSession.sessionId forKey:@"sessionId"];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:URL payload:params];
    command.callbackComplete = ^(NSDictionary * responseObject)
    {
        BOOL running = [[responseObject objectForKey:@"running"] boolValue];
        BOOL visible = [[responseObject objectForKey:@"visible"] boolValue];

        if (success)
            success(running, visible);
    };
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *)subscribeAppState:(LaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/getAppState"];

    NSMutableDictionary *params = [NSMutableDictionary new];
    if (launchSession && launchSession.appId) [params setValue:launchSession.appId forKey:@"appId"];
    if (launchSession && launchSession.sessionId) [params setValue:launchSession.sessionId forKey:@"sessionId"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:params success:^(NSDictionary *responseObject)
    {
        BOOL running = [[responseObject objectForKey:@"running"] boolValue];
        BOOL visible = [[responseObject objectForKey:@"visible"] boolValue];

        if (success)
            success(running, visible);
    } failure:failure];

    return subscription;
}

- (void)closeApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/close"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (launchSession.appId) [payload setValue:launchSession.appId forKey:@"id"]; // yes, this is id not appId (groan)
    if (launchSession.sessionId) [payload setValue:launchSession.sessionId forKey:@"sessionId"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - External Input Control

- (id<ExternalInputControl>)externalInputControl
{
    return self;
}

- (CapabilityPriorityLevel)externalInputControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)launchInputPickerWithSuccess:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApp:@"com.webos.app.inputpicker" success:success failure:failure];
}

- (void)closeInputPicker:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.launcher closeApp:launchSession success:success failure:failure];
}

- (void)getExternalInputListWithSuccess:(ExternalInputListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getExternalInputList"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSArray *externalInputsData = [responseObject objectForKey:@"devices"];
        NSMutableArray *externalInputs = [[NSMutableArray alloc] init];

        [externalInputsData enumerateObjectsUsingBlock:^(NSDictionary *externalInputData, NSUInteger idx, BOOL *stop)
        {
            [externalInputs addObject:[WebOSTVService externalInputInfoFromDictionary:externalInputData]];
        }];

        if (success)
            success(externalInputs);
    };
    command.callbackError = failure;
    [command send];
}

- (void)setExternalInput:(ExternalInputInfo *)externalInputInfo success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/switchInput"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (externalInputInfo && externalInputInfo.id) [payload setValue:externalInputInfo.id forKey:@"inputId"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - Media Player

- (id <MediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    if ([self.serviceDescription.version isEqualToString:@"4.0.0"])
    {
        if (self.dlnaService)
        {
            id<MediaPlayer> mediaPlayer;

            if ([self.dlnaService respondsToSelector:@selector(mediaPlayer)])
                mediaPlayer = [self.dlnaService performSelector:@selector(mediaPlayer)];

            if (mediaPlayer && [mediaPlayer respondsToSelector:@selector(playMedia:iconURL:title:description:mimeType:shouldLoop:success:failure:)])
            {
                [mediaPlayer displayImage:imageURL iconURL:iconURL title:title description:description mimeType:mimeType success:success failure:failure];
                return;
            }
        }

        NSDictionary *params = @{
                @"target" : ensureString(imageURL.absoluteString),
                @"iconSrc" : ensureString(iconURL.absoluteString),
                @"title" : ensureString(title),
                @"description" : ensureString(description),
                @"mimeType" : ensureString(mimeType)
        };

        [self displayMediaWithParams:params success:success failure:failure];
    } else
    {
        NSString *webAppId = @"MediaPlayer";

        WebAppLaunchSuccessBlock connectSuccess = ^(WebAppSession *webAppSession)
        {
            WebOSWebAppSession *session = (WebOSWebAppSession *)webAppSession;
            [session.mediaPlayer displayImage:imageURL iconURL:iconURL title:title description:description mimeType:mimeType success:success failure:failure];
        };

        [self joinWebAppWithId:webAppId success:connectSuccess failure:^(NSError *error)
        {
            [self launchWebApp:webAppId success:connectSuccess failure:failure];
        }];
    }
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    if ([self.serviceDescription.version isEqualToString:@"4.0.0"])
    {
        if (self.dlnaService)
        {
            id<MediaPlayer> mediaPlayer;

            if ([self.dlnaService respondsToSelector:@selector(mediaPlayer)])
                mediaPlayer = [self.dlnaService performSelector:@selector(mediaPlayer)];

            if (mediaPlayer && [mediaPlayer respondsToSelector:@selector(playMedia:iconURL:title:description:mimeType:shouldLoop:success:failure:)])
            {
                [mediaPlayer playMedia:mediaURL iconURL:iconURL title:title description:description mimeType:mimeType shouldLoop:shouldLoop success:success failure:failure];
                return;
            }
        }

        NSDictionary *params = @{
                @"target" : ensureString(mediaURL.absoluteString),
                @"iconSrc" : ensureString(iconURL.absoluteString),
                @"title" : ensureString(title),
                @"description" : ensureString(description),
                @"mimeType" : ensureString(mimeType),
                @"loop" : shouldLoop ? @"true" : @"false"
        };

        [self displayMediaWithParams:params success:success failure:failure];
    } else
    {
        NSString *webAppId = @"MediaPlayer";

        WebAppLaunchSuccessBlock connectSuccess = ^(WebAppSession *webAppSession)
        {
            WebOSWebAppSession *session = (WebOSWebAppSession *)webAppSession;
            [session.mediaPlayer playMedia:mediaURL iconURL:iconURL title:title description:description mimeType:mimeType shouldLoop:shouldLoop success:success failure:failure];
        };

        [self joinWebAppWithId:webAppId success:connectSuccess failure:^(NSError *error)
        {
            [self launchWebApp:webAppId success:connectSuccess failure:failure];
        }];
    }
}

- (void)displayMediaWithParams:(NSDictionary *)params success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.viewer/open"];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:URL payload:params];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:[responseObject objectForKey:@"id"]];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeMedia;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        if (success)
            success(launchSession, self.mediaControl);
    };
    command.callbackError = failure;
    [command send];
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self closeApp:launchSession success:success failure:failure];
}

#pragma mark - Media Control

- (id <MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/play"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/pause"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/stop"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/rewind"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/fastForward"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

#pragma mark - Volume

- (id <VolumeControl>)volumeControl
{
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getMute"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        BOOL mute = [[responseDic objectForKey:@"mute"] boolValue];

        if (success)
            success(mute);
    };

    command.callbackError = failure;
    [command send];
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/setMute"];
    NSDictionary *payload = @{ @"mute" : @(mute) };

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getVolume"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        int fromString = [[responseDic objectForKey:@"volume"] intValue];
        float volVal = fromString / 100.0;

        if (success)
            success(volVal);
    });

    command.callbackError = failure;
    [command send];
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/setVolume"];
    NSDictionary *payload = @{ @"volume" : @(roundf(volume * 100.0f)) };

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/volumeUp"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/volumeDown"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getMute"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        BOOL muteValue = [[responseObject valueForKey:@"mute"] boolValue];

        if (success)
            success(muteValue);
    } failure:failure];

    return subscription;
}

- (ServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getVolume"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        float volumeValue = [[responseObject valueForKey:@"volume"] floatValue] / 100.0;

        if (success)
            success(volumeValue);
    } failure:failure];

    return subscription;
}

#pragma mark - TV

- (id <TVControl>)tvControl
{
    return self;
}

- (CapabilityPriorityLevel)tvControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getCurrentChannelWithSuccess:(CurrentChannelSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getCurrentChannel"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        if (success)
            success([WebOSTVService channelInfoFromDictionary:responseDic]);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getChannelListWithSuccess:(ChannelListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getChannelList"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        NSArray *channels = [responseDic objectForKey:@"channelList"];
        NSMutableArray *channelList = [[NSMutableArray alloc] init];

        [channels enumerateObjectsUsingBlock:^(NSDictionary *channelInfo, NSUInteger idx, BOOL *stop)
        {
            [channelList addObject:[WebOSTVService channelInfoFromDictionary:channelInfo]];
        }];

        if (success)
            success([NSArray arrayWithArray:channelList]);
    });

    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *)subscribeCurrentChannelWithSuccess:(CurrentChannelSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getCurrentChannel"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        ChannelInfo *channelInfo = [WebOSTVService channelInfoFromDictionary:responseObject];

        if (success)
            success(channelInfo);
    } failure:failure];

    return subscription;
}

- (void)channelUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/channelUp"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)channelDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/channelDown"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)setChannel:(ChannelInfo *)channelInfo success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/openChannel"];
    NSDictionary *payload = @{ @"channelId" : channelInfo.id};

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getProgramInfoWithSuccess:(ProgramInfoSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (ServiceSubscription *)subscribeProgramInfoWithSuccess:(ProgramInfoSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)getProgramListWithSuccess:(ProgramListSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (ServiceSubscription *)subscribeProgramListWithSuccess:(ProgramListSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)get3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/get3DStatus"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSDictionary *status3D = [responseObject objectForKey:@"status3D"];
        BOOL status = [[status3D objectForKey:@"status"] boolValue];

        if (success)
            success(status);
    };
    command.callbackError = failure;
    [command send];
}

- (void)set3DEnabled:(BOOL)enabled success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL;

    if (enabled)
        URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/set3DOn"];
    else
        URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/set3DOff"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *)subscribe3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/get3DStatus"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        NSDictionary *status3D = [responseObject objectForKey:@"status3D"];
        BOOL status = [[status3D objectForKey:@"status"] boolValue];

        if (success)
            success(status);
    } failure:failure];

    return subscription;
}

#pragma mark - Key Control

- (id <KeyControl>) keyControl
{
    return self;
}

- (CapabilityPriorityLevel) keyControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) sendMouseButton:(WebOSTVMouseButton)button success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket button:button];

        if (success)
            success(nil);
    } else
    {
        [self.mouseControl connectMouseWithSuccess:^(id responseObject)
        {
            [self.mouseSocket button:button];

            if (success)
                success(nil);
        } failure:failure];
    }
}

- (void)upWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonUp success:success failure:failure];
}

- (void)downWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonDown success:success failure:failure];
}

- (void)leftWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonLeft success:success failure:failure];
}

- (void)rightWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonRight success:success failure:failure];
}

- (void)okWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket click];

        if (success)
            success(nil);
    } else
    {
        [self.mouseControl connectMouseWithSuccess:^(id responseObject)
        {
            [self.mouseSocket click];

            if (success)
                success(nil);
        } failure:failure];
    }
}

- (void)backWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonBack success:success failure:failure];
}

- (void)homeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonHome success:success failure:failure];
}

- (void)sendKeyCode:(NSUInteger)keyCode success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Mouse

- (id<MouseControl>)mouseControl
{
    return self;
}

- (CapabilityPriorityLevel)mouseControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)connectMouseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_mouseSocket || _mouseInit)
        return;

    _mouseInit = YES;

    NSURL *commandURL = [NSURL URLWithString:@"ssap://com.webos.service.networkinput/getPointerInputSocket"];
    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:commandURL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        NSString *socket = [responseDic objectForKey:@"socketPath"];
        _mouseSocket = [[WebOSTVServiceMouse alloc] initWithSocket:socket success:success failure:failure];
    });
    command.callbackError = ^(NSError *error)
    {
        _mouseInit = NO;
        _mouseSocket = nil;

        if (failure)
            failure(error);
    };
    [command send];
}

- (void)disconnectMouse
{
    [_mouseSocket disconnect];
    _mouseSocket = nil;

    _mouseInit = NO;
}

- (void) move:(CGVector)distance success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket move:distance];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"MouseControl socket is not yet initialized."]);
    }
}

- (void) scroll:(CGVector)distance success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket scroll:distance];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"MouseControl socket is not yet initialized."]);
    }
}

- (void)clickWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self okWithSuccess:success failure:failure];
}

#pragma mark - Power

- (id<PowerControl>)powerControl
{
    return self;
}

- (CapabilityPriorityLevel)powerControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)powerOffWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system/turnOff"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        BOOL didTurnOff = [[responseDic objectForKey:@"returnValue"] boolValue];

        if (didTurnOff && success)
            success(nil);
        else if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    });

    command.callbackError = failure;
    [command send];
}

- (void) powerOnWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Web App Launcher

- (id <WebAppLauncher>)webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:nil relaunchIfRunning:relaunchIfRunning success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app id"]);

        return;
    }

    __block WebOSWebAppSession *webAppSession = _webAppSessions[webAppId];

    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/launchWebApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (webAppId) [payload setObject:webAppId forKey:@"webAppId"];
    if (params) [payload setObject:params forKey:@"urlParams"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        LaunchSession *launchSession;

        if (webAppSession)
            launchSession = webAppSession.launchSession;
        else
        {
            launchSession = [LaunchSession launchSessionForAppId:webAppId];
            webAppSession = [[WebOSWebAppSession alloc] initWithLaunchSession:launchSession service:self];
            _webAppSessions[webAppId] = webAppSession;
        }

        launchSession.sessionType = LaunchSessionTypeWebApp;
        launchSession.service = self;
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.rawData = [responseObject copy];

        if (success)
            success(webAppSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You need to provide a valid webAppId."]);

        return;
    }

    if (relaunchIfRunning)
        [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
    else
    {
        [self.launcher getRunningAppWithSuccess:^(AppInfo *appInfo)
        {
            // TODO: this will only work on native apps, currently
            if ([appInfo.id hasSuffix:webAppId])
            {
                LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
                launchSession.sessionType = LaunchSessionTypeWebApp;
                launchSession.service = self;
                launchSession.rawData = appInfo.rawData;

                WebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:launchSession];

                if (success)
                    success(webAppSession);
            } else
            {
                [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
            }
        } failure:failure];
    }
}

- (void)closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession || !launchSession.appId || launchSession.appId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid launch session object"]);

        return;
    }

    WebOSWebAppSession *webAppSession = _webAppSessions[launchSession.appId];

    if (webAppSession && webAppSession.connected)
    {
        // This is a hack to enable closing of bridged web apps that we didn't open
        NSDictionary *closeCommand = @{
                @"contentType" : @"connectsdk.serviceCommand",
                @"serviceCommand" : @{
                        @"type" : @"close"
                }
        };

        [webAppSession sendJSON:closeCommand success:^(id responseObject)
        {
            [webAppSession disconnectFromWebApp];

            if (success)
                success(responseObject);
        } failure:^(NSError *closeError)
        {
            [webAppSession disconnectFromWebApp];

            if (failure)
                failure(closeError);
        }];
    } else
    {
        if (webAppSession)
            [webAppSession disconnectFromWebApp];

        NSURL *URL = [NSURL URLWithString:@"ssap://webapp/closeWebApp"];

        NSMutableDictionary *payload = [NSMutableDictionary new];
        if (launchSession.appId) [payload setValue:launchSession.appId forKey:@"webAppId"];
        if (launchSession.sessionId) [payload setValue:launchSession.sessionId forKey:@"sessionId"];

        ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
        command.callbackComplete = success;
        command.callbackError = failure;
        [command send];
    }
}

- (void)joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    WebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:webAppLaunchSession];

    [webAppSession joinWithSuccess:^(id responseObject)
    {
        if (success)
            success(webAppSession);
    } failure:failure];
}

- (void)joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    [self joinWebApp:launchSession success:success failure:failure];
}

- (void) connectToWebApp:(WebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!_webAppSessions)
        _webAppSessions = [NSMutableDictionary new];

    if (!_appToAppIdMappings)
        _appToAppIdMappings = [NSMutableDictionary new];

    if (!webAppSession || !webAppSession.launchSession)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid LaunchSession object."]);
        return;
    }

    NSString *appId = webAppSession.launchSession.appId;
    NSString *idKey;

    if (webAppSession.launchSession.sessionType == LaunchSessionTypeWebApp)
        idKey = @"webAppId";
    else
        idKey = @"appId";

    if (!appId || appId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app session"]);

        return;
    }

    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/connectToApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:appId forKey:idKey];

    FailureBlock connectFailure = ^(NSError *error)
    {
        [webAppSession disconnectFromWebApp];

        BOOL appChannelDidClose = [error.localizedDescription rangeOfString:@"app channel closed"].location != NSNotFound;

        if (appChannelDidClose)
        {
            if (webAppSession && webAppSession.delegate && [webAppSession.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
                [webAppSession.delegate webAppSessionDidDisconnect:webAppSession];
        } else
        {
            if (failure)
                failure(error);
        }
    };

    SuccessBlock connectSuccess = ^(id responseObject) {
        NSString *state = [responseObject objectForKey:@"state"];

        if (![state isEqualToString:@"CONNECTED"])
        {
            if (joinOnly && [state isEqualToString:@"WAITING_FOR_APP"])
            {
                if (connectFailure)
                    connectFailure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Web app is not currently running"]);
            }

            return;
        }

        NSString *fullAppId = responseObject[@"appId"];

        if (fullAppId)
        {
            if (webAppSession.launchSession.sessionType == LaunchSessionTypeWebApp)
                _appToAppIdMappings[fullAppId] = appId;

            webAppSession.fullAppId = fullAppId;
        }

        if (success)
            success(responseObject);
    };
    
    ServiceSubscription *appToAppSubscription = [ServiceSubscription subscriptionWithDelegate:webAppSession.socket target:URL payload:payload callId:-1];
    [appToAppSubscription addSuccess:connectSuccess];
    [appToAppSubscription addFailure:connectFailure];
    
    webAppSession.appToAppSubscription = appToAppSubscription;
    [appToAppSubscription subscribe];
}

- (WebOSWebAppSession *) webAppSessionForLaunchSession:(LaunchSession *)launchSession
{
    if (!_webAppSessions)
        _webAppSessions = [NSMutableDictionary new];

    if (!launchSession.service)
        launchSession.service = self;

    WebOSWebAppSession *webAppSession = _webAppSessions[launchSession.appId];

    if (!webAppSession)
    {
        webAppSession = [[WebOSWebAppSession alloc] initWithLaunchSession:launchSession service:self];
        _webAppSessions[launchSession.appId] = webAppSession;
    }

    return webAppSession;
}

- (NSDictionary *) appToAppIdMappings
{
    return [NSDictionary dictionaryWithDictionary:_appToAppIdMappings];
}

- (NSDictionary *) webAppSessions
{
    return [NSDictionary dictionaryWithDictionary:_webAppSessions];
}

#pragma mark - Text Input Control

- (id<TextInputControl>) textInputControl
{
    return self;
}

- (CapabilityPriorityLevel) textInputControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) sendText:(NSString *)input success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [_keyboardQueue addObject:input];

    if (!_keyboardQueueProcessing)
        [self sendKeys];
}

- (void)sendEnterWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [_keyboardQueue addObject:kKeyboardEnter];

    if (!_keyboardQueueProcessing)
        [self sendKeys];
}

- (void)sendDeleteWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [_keyboardQueue addObject:kKeyboardDelete];

    if (!_keyboardQueueProcessing)
        [self sendKeys];
}

- (void) sendKeys
{
    _keyboardQueueProcessing = YES;

    NSString *target;
    NSString *key = [_keyboardQueue firstObject];
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];

    if ([key isEqualToString:kKeyboardEnter])
    {
        [_keyboardQueue removeObjectAtIndex:0];
        target = @"ssap://com.webos.service.ime/sendEnterKey";
    } else if ([key isEqualToString:kKeyboardDelete])
    {
        target = @"ssap://com.webos.service.ime/deleteCharacters";

        int count = 0;

        for (NSUInteger i = 0; i < _keyboardQueue.count; i++)
        {
            if ([[_keyboardQueue objectAtIndex:i] isEqualToString:kKeyboardDelete]) {
                count++;
            } else {
                break;
            }
        }

        NSRange deleteRange = NSMakeRange(0, count);
        [_keyboardQueue removeObjectsInRange:deleteRange];

        [payload setObject:@(count) forKey:@"count"];
    } else
    {
        target = @"ssap://com.webos.service.ime/insertText";
        NSMutableString *stringToSend = [[NSMutableString alloc] init];

        int count = 0;

        for (NSUInteger i = 0; i < _keyboardQueue.count; i++)
        {
            NSString *text = [_keyboardQueue objectAtIndex:i];

            if (![text isEqualToString:kKeyboardEnter] && ![text isEqualToString:kKeyboardDelete]) {
                [stringToSend appendString:text];
                count++;
            } else {
                break;
            }
        }

        NSRange textRange = NSMakeRange(0, count);
        [_keyboardQueue removeObjectsInRange:textRange];

        [payload setObject:stringToSend forKey:@"text"];
        [payload setObject:@(NO) forKey:@"replace"];
    }

    NSURL *URL = [NSURL URLWithString:target];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = ^(id responseObject)
    {
        _keyboardQueueProcessing = NO;

        if (_keyboardQueue.count > 0)
            [self sendKeys];
    };
    command.callbackError = ^(NSError *error)
    {
        _keyboardQueueProcessing = NO;

        if (_keyboardQueue.count > 0)
            [self sendKeys];
    };
    [command send];
}

- (ServiceSubscription *) subscribeTextInputStatusWithSuccess:(TextInputStatusInfoSuccessBlock)success failure:(FailureBlock)failure
{
    _keyboardQueue = [[NSMutableArray alloc] init];
    _keyboardQueueProcessing = NO;

    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.ime/registerRemoteKeyboard"];

    ServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        BOOL isVisible = [[[responseObject objectForKey:@"currentWidget"] objectForKey:@"focus"] boolValue];
        NSString *type = [[responseObject objectForKey:@"currentWidget"] objectForKey:@"contentType"];

        UIKeyboardType keyboardType = UIKeyboardTypeDefault;

        if ([type isEqualToString:@"url"])
            keyboardType = UIKeyboardTypeURL;
        else if ([type isEqualToString:@"number"])
            keyboardType = UIKeyboardTypeNumberPad;
        else if ([type isEqualToString:@"phonenumber"])
            keyboardType = UIKeyboardTypeNamePhonePad;
        else if ([type isEqualToString:@"email"])
            keyboardType = UIKeyboardTypeEmailAddress;

        TextInputStatusInfo *keyboardInfo = [[TextInputStatusInfo alloc] init];
        keyboardInfo.isVisible = isVisible;
        keyboardInfo.keyboardType = keyboardType;
        keyboardInfo.rawData = [responseObject copy];

        if (success)
            success(keyboardInfo);
    } failure:failure];

    return subscription;
}

#pragma mark - Toast Control

- (id<ToastControl>)toastControl
{
    return self;
}

- (CapabilityPriorityLevel)toastControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)showToast:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showToast:(NSString *)message iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (iconData) [params setValue:iconData forKey:@"iconData"];
    if (iconExtension) [params setValue:iconExtension forKey:@"iconExtension"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message appInfo:(AppInfo *)appInfo params:(NSDictionary *)launchParams success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (appInfo) [params setValue:appInfo.id forKey:@"target"];
    if (launchParams) [params setValue:launchParams forKey:@"params"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message appInfo:(AppInfo *)appInfo params:(NSDictionary *)launchParams iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (appInfo) [params setValue:appInfo.id forKey:@"target"];
    if (launchParams) [params setValue:launchParams forKey:@"params"];
    if (iconData) [params setValue:iconData forKey:@"iconData"];
    if (iconExtension) [params setValue:iconExtension forKey:@"iconExtension"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message URL:(NSURL *)URL success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (URL) [params setValue:URL.absoluteString forKey:@"target"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message URL:(NSURL *)URL iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (URL) [params setValue:URL.absoluteString forKey:@"target"];
    if (iconData) [params setValue:iconData forKey:@"iconData"];
    if (iconExtension) [params setValue:iconExtension forKey:@"iconExtension"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void) showToastWithParams:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *toastParams = [NSMutableDictionary dictionaryWithDictionary:params];

    if ([toastParams objectForKey:@"iconData"] == nil)
    {
        NSString *imageName = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"] objectAtIndex:0];

        if (imageName == nil)
            imageName = [[[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"] firstObject];

        UIImage *appIcon = [UIImage imageNamed:imageName];
        NSString *dataString;

        if (appIcon)
            dataString = [UIImagePNGRepresentation(appIcon) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

        if (dataString)
        {
            [toastParams setObject:dataString forKey:@"iconData"];
            [toastParams setObject:@"png" forKey:@"iconExtension"];
        }
    }

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self.socket target:[NSURL URLWithString:@"ssap://system.notifications/createToast"] payload:toastParams];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - System info

- (void)getServiceListWithSuccess:(ServiceListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://api/getServiceList"];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSArray *services = [responseObject objectForKey:@"services"];

        if (success)
            success(services);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getSystemInfoWithSuccess:(SystemInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system/getSystemInfo"];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSArray *features = [responseObject objectForKey:@"features"];

        if (success)
            success(features);
    };
    command.callbackError = failure;
    [command send];
}

@end
