//
//  WebOSService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import "WebOSTVService.h"
#import "LGSRWebSocket.h"
#import "ConnectError.h"
#import "DiscoveryManager.h"
#import "ServiceAsyncCommand.h"
#import "WebOSWebAppSession.h"

#define kKeyboardEnter @"ENTER"
#define kKeyboardDelete @"DELETE"

@interface WebOSTVService () <LGSRWebSocketDelegate, ServiceCommandDelegate, UIAlertViewDelegate>
{
    int UID;

    LGSRWebSocket *_socket;
    NSMutableArray *_commandQueue;
    NSMutableDictionary *_activeConnections;
    NSMutableDictionary *_appToAppMessageCallbacks;
    NSMutableDictionary *_appToAppSubscriptions;

    NSMutableDictionary *_subscribed;

    NSTimer *_pairingTimer;
    UIAlertView *_pairingAlert;

    NSMutableArray *_keyboardQueue;
    BOOL _keyboardQueueProcessing;

    BOOL _mouseInit;
    BOOL _reconnectOnWake;
}

@end

@implementation WebOSTVService

@synthesize serviceConfig = _serviceConfig;
@synthesize connected = _connected;
@synthesize permissions = _permissions;
@synthesize serviceDescription = _serviceDescription;

#pragma mark - Setup

- (instancetype) initWithServiceConfig:(ServiceConfig *)serviceConfig
{
    self = [super init];

    if (self)
    {
        if ([serviceConfig isKindOfClass:[WebOSTVServiceConfig class]])
            _serviceConfig = (WebOSTVServiceConfig *) serviceConfig;
        else
        {
            _serviceConfig = [[WebOSTVServiceConfig alloc] initWithServiceDescription:self.serviceDescription];
            _serviceConfig.delegate = serviceConfig.delegate;
        }

        _commandQueue = [[NSMutableArray alloc] init];
        _activeConnections = [[NSMutableDictionary alloc] init];

        UID = 0;
    }

    return self;
}

#pragma mark - Inherited methods

- (void) setServiceDescription:(ServiceDescription *)serviceDescription
{
    _serviceDescription = serviceDescription;

    NSString *serverInfo = [_serviceDescription.locationResponseHeaders objectForKey:@"Server"];
    NSString *systemOS = [[serverInfo componentsSeparatedByString:@" "] firstObject];
    NSString *systemVersion = [[systemOS componentsSeparatedByString:@"/"] lastObject];

    _serviceDescription.version = systemVersion;
}

- (NSArray *)capabilities
{
    // TODO: dynamically change capability on 4.0.0 to remove app 2 app support

    NSArray *caps = [NSArray array];

    if ([DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn)
    {
        caps = [caps arrayByAddingObjectsFromArray:@[
                kKeyControlSendKeyCode,
                kKeyControlUp,
                kKeyControlDown,
                kKeyControlLeft,
                kKeyControlRight,
                kKeyControlHome,
                kKeyControlBack,
                kKeyControlOK
        ]];
        caps = [caps arrayByAddingObjectsFromArray:kMouseControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kTextInputControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kPowerControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kLauncherCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kTVControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kExternalInputControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kWebAppLauncherCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kToastControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kMediaControlCapabilities];
    } else
    {
        caps = [caps arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:kWebAppLauncherCapabilities];
        caps = [caps arrayByAddingObjectsFromArray:@[
                kLauncherApp,
                kLauncherAppParams,
                kLauncherAppClose,
                kLauncherBrowser,
                kLauncherBrowserParams,
                kLauncherHulu,
                kLauncherHuluParams,
                kLauncherNetflix,
                kLauncherNetflixParams,
                kLauncherYouTube,
                kLauncherYouTubeParams,
                kLauncherAppState,
                kLauncherAppStateSubscribe
        ]];
        caps = [caps arrayByAddingObjectsFromArray:@[
                kMediaControlPlay,
                kMediaControlPause,
                kMediaControlStop,
                kMediaControlRewind,
                kMediaControlFastForward
        ]];
    }

    return caps;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId":@"WebOS TV",
             @"ssdp":@{
                     @"filter":@"urn:lge-com:service:webos-second-screen:1"
                  }
             };
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    [self openSocket];
}

- (BOOL) connected
{
    if ([DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn)
        return _connected && self.serviceConfig.clientKey != nil;
    else
        return _connected;
}

- (void) openSocket
{
    NSString *address = self.serviceDescription.address;
    unsigned long port = self.serviceDescription.port;

    NSString *socketPath = [NSString stringWithFormat:@"wss://%@:%lu", address, port];
    NSURL *url = [[NSURL alloc] initWithString:socketPath];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];

    if (self.serviceConfig.SSLCertificates)
        [urlRequest setLGSR_SSLPinnedCertificates:self.serviceConfig.SSLCertificates];

    _socket = [[LGSRWebSocket alloc] initWithURLRequest:urlRequest];
    _socket.delegate = self;
    [_socket open];
}

- (void) disconnect
{
    [self disconnectWithError:nil];
}

- (void) disconnectWithError:(NSError *)error
{
    if (!_connected)
        return;

    if (!_reconnectOnWake)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }

    _connected = NO;

    if (_socket && _socket.readyState != LGSR_CLOSED && _socket.readyState != LGSR_CLOSING)
    {
        if (error)
            [_socket closeWithCode:LGSRStatusCodeNormal reason:error.localizedDescription];
        else
            [_socket closeWithCode:LGSRStatusCodeNormal reason:@"Disconnected by client"];
    }

    if ([self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

- (void) hAppDidEnterBackground:(NSNotification *)notification
{
    if (_connected)
    {
        _reconnectOnWake = YES;
        [self disconnect];
    }
}

- (void) hAppDidBecomeActive:(NSNotification *)notification
{
    if (_reconnectOnWake)
    {
        [self connect];
        _reconnectOnWake = NO;
    }
}

#pragma mark - Initial connection & pairing

- (BOOL) requiresPairing
{
    return [DiscoveryManager sharedManager].pairingLevel == ConnectableDevicePairingLevelOn;
}

-(void) helloTv
{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
    NSString *screenResolution = [NSString stringWithFormat:@"%dx%d", (int)screenSize.width, (int)screenSize.height];

    NSDictionary *payload = @{
            @"sdkVersion" : @(CONNECT_SDK_VERSION),
            @"deviceModel" : ensureString([[UIDevice currentDevice] model]),
            @"OSVersion" : ensureString([infoDic objectForKey:@"DTPlatformVersion"]),
            @"resolution" : screenResolution,
            @"appId" : ensureString([infoDic objectForKey:@"CFBundleIdentifier"]),
            @"appName" : ensureString([infoDic objectForKey:@"CFBundleDisplayName"]),
            @"appRegion" : ensureString([infoDic objectForKey:@"CFBundleDevelopmentRegion"])
    };

    ServiceCommand *hello = [[ServiceCommand alloc] init];
    hello.payload = payload;

    hello.delegate = self;
    hello.callbackComplete = ^(NSDictionary* response){
        if (self.serviceConfig.UUID != nil)
        {
            if (![self.serviceConfig.UUID isEqualToString:[response objectForKey:@"deviceUUID"]])
            {
                //Imposter UUID, kill it, kill it with fire
                self.serviceConfig.clientKey = nil;
                self.serviceConfig.SSLCertificates = nil;
                self.serviceConfig.UUID = nil;
                self.serviceDescription.address = nil;
                self.serviceDescription.UUID = nil;

                NSError *UUIDError = [ConnectError generateErrorWithCode:ConnectStatusCodeCertificateError andDetails:nil];
                [self disconnectWithError:UUIDError];
            }
        } else
        {
            self.serviceConfig.UUID = self.serviceDescription.UUID = [response objectForKey:@"deviceUUID"];
        }

        [self registerWithTv];
    };

    hello.callbackError = ^(NSError*err)
    {
        NSError *connectionError = [ConnectError generateErrorWithCode:ConnectStatusCodeSocketError andDetails:nil];
        [self disconnectWithError:connectionError];
    };

    if (_activeConnections == nil)
        _activeConnections = [[NSMutableDictionary alloc] init];

    [_activeConnections setValue:hello forKey:@"hello"];

    int dataId = [self getNextId];

    NSDictionary *sendData = @{
            @"id" : @(dataId),
            @"type" : @"hello",
            @"payload" : hello.payload
    };

    NSString *sendString = [self writeToJSON:sendData];
    [_socket send:sendString];

    if ([_commandQueue containsObject:sendString])
        [_commandQueue removeObject:sendString];
}

-(void) registerWithTv
{
    _pairingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showAlert) userInfo:nil repeats:NO];

    ServiceCommand *reg = [[ServiceCommand alloc] init];
    reg.delegate = self;

    reg.callbackComplete = ^(NSDictionary* response)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hAppDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        if ([self.delegate respondsToSelector:@selector(deviceServicePairingSuccess:)])
            dispatch_on_main(^{ [self.delegate deviceServicePairingSuccess:self]; });

        if ([self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
            dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });

        if([_commandQueue count] > 0)
        {
            [_commandQueue enumerateObjectsUsingBlock:^(NSString *sendString, NSUInteger idx, BOOL *stop)
            {
                [_socket send:sendString];
            }];

            _commandQueue = [[NSMutableArray alloc] init];
        }
    };
    // TODO: this is getting cleaned up before a potential pairing cancelled message is received
    reg.callbackError = ^(NSError *error) {
        if (_pairingAlert && _pairingAlert.isVisible)
            dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:0 animated:NO]; });

        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:pairingFailedWithError:)])
            dispatch_on_main(^{ [self.delegate deviceService:self pairingFailedWithError:error]; });
    };

    int dataId = [self getNextId];

    [_activeConnections setObject:reg forKey:[NSString stringWithFormat:@"req%d",dataId]];

    NSDictionary *registerInfo = @{
            @"manifest" : self.manifest
    };

    NSString *sendString = [self encodeData:registerInfo andAddress:nil withId:dataId];
    [_socket send:sendString];

    if ([_commandQueue containsObject:sendString])
        [_commandQueue removeObject:sendString];
}

#pragma mark - Paring alert

-(void) showAlert
{
    NSString *title = NSLocalizedStringFromTable(@"Connect_SDK_Pair_Title", @"ConnectSDKStrings", nil);
    NSString *message = NSLocalizedStringFromTable(@"Connect_SDK_Pair_Request", @"ConnectSDKStrings", nil);
    NSString *ok = NSLocalizedStringFromTable(@"Connect_SDK_Pair_OK", @"ConnectSDKStrings", nil);
    NSString *cancel = NSLocalizedStringFromTable(@"Connect_SDK_Pair_Cancel", @"ConnectSDKStrings", nil);
    
    _pairingAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil];
    dispatch_on_main(^{ [_pairingAlert show]; });
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        [self disconnect];
}

#pragma mark - LGSRWebSocketDelegate

- (void)webSocketDidOpen:(LGSRWebSocket *)webSocket
{
    _connected = YES;
    [self helloTv];
}

- (void)webSocket:(LGSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    _connected = NO;

    _socket.delegate = nil;
    _socket = nil;

    NSError *error;

    if (!wasClean)
        error = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:reason];

    if ([self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

- (void)webSocket:(LGSRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    BOOL shouldRetry = NO;
    BOOL wasConnected = _connected;
    _connected = NO;
    
    if (_pairingAlert && _pairingAlert.visible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:0 animated:YES]; });

    NSError *intError;
    
    if (error.code == 23556)
    {
        intError = [ConnectError generateErrorWithCode:ConnectStatusCodeCertificateError andDetails:nil];
        
        self.serviceConfig.SSLCertificates = nil;
        self.serviceConfig.clientKey = nil;

        shouldRetry = YES;
    } else
        intError = [ConnectError generateErrorWithCode:ConnectStatusCodeSocketError andDetails:error.localizedDescription];

    for (NSString *key in _activeConnections)
    {
        ServiceCommand *comm = (ServiceCommand *)[_activeConnections objectForKey:key];

        if (comm.callbackError)
            dispatch_on_main(^{ comm.callbackError(intError); });
    }

    _appToAppMessageCallbacks = [NSMutableDictionary dictionary];
    _appToAppSubscriptions = [NSMutableDictionary dictionary];
    _activeConnections = [NSMutableDictionary dictionary];

    if (shouldRetry)
    {
        [self connect];
        return;
    }
    
    if (wasConnected)
    {
        if ([self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
            dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:intError]; });
    } else
    {
        if ([self.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)])
            dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:intError]; });
    }
}

- (void)webSocket:(LGSRWebSocket *)webSocket didGetCertificates:(NSArray *)certs
{
    self.serviceConfig.SSLCertificates = certs;
}

- (void)webSocket:(LGSRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSDictionary *decodeData = [self decodeData:message];
    NSNumber *comId = [decodeData objectForKey:@"id"];
    NSString *type = [decodeData objectForKey:@"type"];

    if ([type isEqualToString:@"error"])
    {
        if (comId)
        {
            ServiceCommand *comm = [_activeConnections objectForKey:[NSString stringWithFormat:@"req%@", comId]];

            if (comm.callbackError != nil)
            {
                NSError *err = [ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:decodeData];
                dispatch_on_main(^{ comm.callbackError(err); });
            }
        }
    } else if ([type isEqualToString:@"p2p"])
    {
        NSString *fromAppId = [decodeData objectForKey:@"from"];
        id messageContent = [decodeData objectForKey:@"payload"];
        WebAppMessageBlock messageHandler = [_appToAppMessageCallbacks objectForKey:fromAppId];

        if (messageHandler)
            dispatch_on_main(^{ messageHandler(messageContent); });
    } else
    {
        NSDictionary *payload = [decodeData objectForKey:@"payload"];

        if ([type isEqualToString:@"registered"])
        {
            [_pairingTimer invalidate];

            NSString *client = [payload objectForKey:@"client-key"];
            self.serviceConfig.clientKey = client;

            if (_pairingAlert && _pairingAlert.visible)
                dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:1 animated:YES]; });

            if ([self.delegate respondsToSelector:@selector(deviceServicePairingSuccess:)])
                dispatch_on_main(^{ [self.delegate deviceServicePairingSuccess:self]; });

            if ([self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
                dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
        } else if ([type isEqualToString:@"hello"])
        {
            //Store information here
            ServiceCommand *comm = [_activeConnections objectForKey:[NSString stringWithFormat:@"hello"]];

            if (comm.callbackComplete)
                dispatch_on_main(^{ comm.callbackComplete(payload); });

            [_activeConnections removeObjectForKey:@"hello"];
        }

        if (comId)
        {
            ServiceCommand *comm = [_activeConnections objectForKey:[NSString stringWithFormat:@"req%@", comId]];

            if(comm.callbackComplete)
                dispatch_on_main(^{ comm.callbackComplete(payload); });
        }
    }

    if (![[_activeConnections objectForKey:[NSString stringWithFormat:@"req%@", comId]] isKindOfClass:[ServiceSubscription class]])
        [_activeConnections removeObjectForKey:[NSString stringWithFormat:@"req%@", comId]];
}

#pragma mark - Subscription methods

- (ServiceSubscription *) addSubscribe:(NSURL *)URL payload:(NSDictionary *)payload success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_subscribed == nil)
        _subscribed = [[NSMutableDictionary alloc] init];

    NSString *subscriptionReferenceId = [self subscriptionReferenceForURL:URL payload:payload];
    ServiceSubscription *subscription = [_subscribed objectForKey:subscriptionReferenceId];

    if (subscription == nil)
    {
        int callId = [self getNextId];
        subscription = [ServiceSubscription subscriptionWithDelegate:self target:URL payload:payload callId:callId];
        [_subscribed setObject:subscription forKey:subscriptionReferenceId];
    }

    if (success)
        [subscription addSuccess:success];

    if (failure)
        [subscription addFailure:failure];

    if (![subscription isSubscribed])
        [subscription subscribe];

    return subscription;
}

- (ServiceSubscription *) killSubscribe:(NSURL *)URL payload:(NSDictionary *)payload
{
    NSString *subscriptionReferenceId = [self subscriptionReferenceForURL:URL payload:payload];
    ServiceSubscription *subscription = [_subscribed objectForKey:subscriptionReferenceId];

    if (subscription)
        [_subscribed removeObjectForKey:subscriptionReferenceId];

    return subscription;
}

- (NSString *)subscriptionReferenceForURL:(NSURL *)URL payload:(NSDictionary *)payload
{
    NSString *subscriptionReferenceId;

    if (payload)
    {
        NSString *payloadKeys = [[payload allValues] componentsJoinedByString:@""];
        subscriptionReferenceId = [NSString stringWithFormat:@"%@%@", URL.absoluteString, payloadKeys];
    } else
    {
        subscriptionReferenceId = URL.absoluteString;
    }

    return subscriptionReferenceId;
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (callId < 0)
        callId = [self getNextId];

    NSString *subscriptionKey = [NSString stringWithFormat:@"req%d", callId];

    [_activeConnections setObject:subscription forKey:subscriptionKey];

    NSMutableDictionary *subscriptionPayload = [[NSMutableDictionary alloc] init];
    [subscriptionPayload setObject:@(callId) forKey:@"id"];
    [subscriptionPayload setObject:URL.absoluteString forKey:@"uri"];

    if (type == ServiceSubscriptionTypeSubscribe)
    {
        [subscriptionPayload setObject:@"subscribe" forKey:@"type"];

        if (payload)
            [subscriptionPayload setObject:payload forKey:@"payload"];
    } else
    {
        if (!_connected)
            return -1;

        [subscriptionPayload setObject:@"unsubscribe" forKey:@"type"];
        [self killSubscribe:URL payload:payload];
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:subscriptionPayload options:0 error:nil];
    NSString *sendString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    if ([_socket readyState] == LGSR_OPEN)
    {
        [_socket send:sendString];

        if ([_commandQueue containsObject:sendString])
            [_commandQueue removeObject:sendString];
    } else if ([_socket readyState] == LGSR_CONNECTING)
    {
        [_commandQueue addObject:sendString];
    } else
    {
        [_socket open];

        [_commandQueue addObject:sendString];
    }

    return callId;
}

#pragma mark - Helper methods

- (NSDictionary *) manifest
{
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];

    return @{
            @"manifestVersion" : @(1),
            @"appId" : [infoDic objectForKey:@"CFBundleIdentifier"],
            @"vendorId" : @"",
            @"localizedAppNames" : @{
                    @"" : [infoDic objectForKey:@"CFBundleDisplayName"]
            },
            @"permissions" : self.permissions
    };
}

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

- (NSDictionary *) decodeData:(NSString *) data
{
    return [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (NSString *) writeToJSON:(id) obj
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonString;
}

- (NSString*) encodeData:(NSDictionary*)data andAddress:(NSURL*)add withId:(int)reqId{
    NSMutableDictionary *sendData = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *payloadData = [[NSMutableDictionary alloc] initWithDictionary:data];

    if (reqId < 0)
        reqId = [self getNextId];

    [sendData setObject:[NSString stringWithFormat:@"%d", reqId] forKey:@"id"];
    [sendData setObject:payloadData forKey:@"payload"];

    if (add != nil)
    {
        [sendData setObject:[add absoluteString] forKey:@"uri"];
        [sendData setObject:@"request" forKey:@"type"];
    } else
    {
        if (self.serviceConfig.clientKey)
            [payloadData setObject:self.serviceConfig.clientKey forKey:@"client-key"];

        [sendData setObject:@"register" forKey:@"type"];
    }

    return [self writeToJSON:sendData];
}

- (int) getNextId
{
    UID = UID + 1;
    return UID;
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

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(ServiceCommand *)comm withPayload:(NSDictionary *)payload toURL:(NSURL *)URL
{
    if (_socket == nil)
        [self openSocket];

    int callId = [self getNextId];

    [_activeConnections setObject:comm forKey:[NSString stringWithFormat:@"req%d",callId]];

    NSString *sendString = [self encodeData:payload andAddress:URL withId:callId];

    if (_socket.readyState == LGSR_OPEN)
    {
        [_socket send:sendString];

        if ([_commandQueue containsObject:sendString])
            [_commandQueue removeObject:sendString];
    } else if (_socket.readyState == LGSR_CONNECTING ||
            _socket.readyState == LGSR_CLOSING)
    {
        [_commandQueue addObject:sendString];
    } else
    {
        [_commandQueue addObject:sendString];
        [self openSocket];
    }

    return callId;
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

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:URL payload:nil];
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
    
    NSMutableDictionary *payload = [NSMutableDictionary dictionaryWithDictionary:params];
    [payload setValue:appId forKey:@"id"];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:URL payload:payload];
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

- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/open"];
    NSDictionary *params = @{ @"target" : target.absoluteString };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:URL payload:params];
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
    
    [self launchApplication:@"youtube.leanback.v4" withParams:params success:success failure:failure];
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

- (ServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/getForegroundAppInfo"];

    ServiceSubscription *subscription = [self addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
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

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self target:URL payload:nil];
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

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:URL payload:params];
    command.callbackComplete = ^(NSDictionary * responseObject)
    {
        // TODO: need to test this
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

    ServiceSubscription *subscription = [self addSubscribe:URL payload:params success:^(NSDictionary *responseObject)
    {
        // TODO: need to test this
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];
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
    NSDictionary *params = @{
            @"target" : imageURL.absoluteString,
            @"title" : title,
            @"description" : description,
            @"mimeType" : mimeType,
            @"iconSrc" : (iconURL == nil) ? @"" : iconURL.absoluteString
    };

    [self displayMediaWithParams:params success:success failure:failure];
}

- (void) playMedia:(NSURL *)videoURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params = @{
            @"target" : videoURL.absoluteString,
            @"title" : ensureString(title),
            @"description" : ensureString(description),
            @"mimeType" : ensureString(mimeType),
            @"loop" : shouldLoop ? @"true" : @"false",
            @"iconSrc" : (iconURL == nil) ? @"" : iconURL.absoluteString
    };

    [self launchWebApp:@"MediaPlayer" params:params success:^(WebAppSession *webAppSession)
    {
        if (success)
            success(webAppSession.launchSession, webAppSession);
    } failure:failure];
}

- (void)displayMediaWithParams:(NSDictionary *)params success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.viewer/open"];

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:URL payload:params];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/pause"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/stop"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/rewind"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/fastForward"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];

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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getVolume"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];

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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/volumeUp"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/volumeDown"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getMute"];

    ServiceSubscription *subscription = [self addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
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

    ServiceSubscription *subscription = [self addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];

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

    ServiceSubscription *subscription = [self addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)channelDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/channelDown"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)setChannel:(ChannelInfo *)channelInfo success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/openChannel"];
    NSDictionary *payload = @{ @"channelId" : channelInfo.id};

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *)subscribe3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/get3DStatus"];

    ServiceSubscription *subscription = [self addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
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
    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:commandURL payload:nil];

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

- (void)moveWithX:(double)xVal andY:(double)yVal success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket moveWithX:xVal andY:yVal];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"MouseControl socket is not yet initialized."]);
    }
}

- (void)scrollWithX:(double)xVal andY:(double)yVal success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket scrollWithX:xVal andY:yVal];

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

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:nil];

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
    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/launchWebApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (webAppId) [payload setObject:webAppId forKey:@"webAppId"];
    if (params) [payload setObject:params forKey:@"urlParams"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeWebApp;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        WebOSWebAppSession *webAppSession = [[WebOSWebAppSession alloc] initWithLaunchSession:launchSession service:self];

        if (success)
            success(webAppSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You need to provide a webAppId."]);

        return;
    }

    if (relaunchIfRunning)
        [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
    else
    {
        [self.launcher getRunningAppWithSuccess:^(AppInfo *appInfo)
        {
            // TODO: this will only work on pinned apps, currently
            if ([appInfo.id hasSuffix:webAppId])
            {
                LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
                launchSession.sessionType = LaunchSessionTypeWebApp;
                launchSession.service = self;

                WebOSWebAppSession *webAppSession = [[WebOSWebAppSession alloc] initWithLaunchSession:launchSession service:self];

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
    if (!launchSession)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid launch session object"]);
        return;
    }

    if (!launchSession.sessionId)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Cannot close webapp without a launch session id"]);
        return;
    }

    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/closeWebApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (launchSession.appId) [payload setValue:launchSession.appId forKey:@"webAppId"];
    if (launchSession.sessionId) [payload setValue:launchSession.sessionId forKey:@"sessionId"];

    ServiceCommand *command = [ServiceAsyncCommand commandWithDelegate:self target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)connectToWebApp:(WebOSWebAppSession *)webAppSession messageCallback:(WebAppMessageBlock)messageCallback success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!_appToAppMessageCallbacks)
        _appToAppMessageCallbacks = [NSMutableDictionary new];

    if (!_appToAppSubscriptions)
        _appToAppSubscriptions = [NSMutableDictionary new];

    if (!webAppSession || !webAppSession.launchSession || !webAppSession.launchSession.rawData)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid LaunchSession object."]);
        return;
    }

    if (!messageCallback)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a message handler callback."]);
        return;
    }

    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/connectToApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:ensureString(webAppSession.launchSession.appId) forKey:@"webAppId"];
    
    SuccessBlock connectSuccess = ^(id responseObject) {
        NSString *state = [responseObject objectForKey:@"state"];
        
        if (![state isEqualToString:@"CONNECTED"])
            return;
        
        NSString *appId = [responseObject objectForKey:@"appId"];

        if (appId)
        {
            [_appToAppMessageCallbacks setObject:messageCallback forKey:appId];

            NSMutableDictionary *newRawData = [NSMutableDictionary dictionaryWithDictionary:webAppSession.launchSession.rawData];
            [newRawData setObject:appId forKey:@"webAppId"];
            webAppSession.launchSession.rawData = [NSDictionary dictionaryWithDictionary:newRawData];
        }

        if (success)
            success(responseObject);
    };

    FailureBlock connectFailure = ^(NSError *error)
    {
        ServiceSubscription *connectionSubscription = [_appToAppSubscriptions objectForKey:webAppSession.launchSession.appId];

        if (connectionSubscription)
        {
            // TODO: test this
            if ([self.serviceDescription.version rangeOfString:@"4.0"].location != NSNotFound)
            {
                [connectionSubscription unsubscribe];
                [_appToAppSubscriptions removeObjectForKey:webAppSession.launchSession.appId];
            }
        }

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
    
    ServiceSubscription *subscription = [self addSubscribe:URL payload:payload success:connectSuccess failure:connectFailure];
    [_appToAppSubscriptions setObject:subscription forKey:webAppSession.launchSession.appId];
}

- (void)disconnectFromWebApp:(WebOSWebAppSession *)webAppSession
{
    __block NSString *appId = [webAppSession.launchSession.rawData objectForKey:@"webAppId"];

    if (!appId)
    {
        [_appToAppMessageCallbacks enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop)
        {
            if ([key rangeOfString:webAppSession.launchSession.appId].location != NSNotFound)
            {
                appId = key;
                *stop = YES;
            }
        }];
    }

    if (appId)
        [_appToAppMessageCallbacks removeObjectForKey:appId];

    ServiceSubscription *connectionSubscription = [_appToAppSubscriptions objectForKey:webAppSession.launchSession.appId];

    if (connectionSubscription)
    {
        // TODO: test this
        if ([self.serviceDescription.version rangeOfString:@"4.0"].location != NSNotFound)
        {
            [connectionSubscription unsubscribe];
            [_appToAppSubscriptions removeObjectForKey:webAppSession.launchSession.appId];
        }
    }
}

- (int) sendMessage:(id)message toApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession || !launchSession.rawData)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid LaunchSession to send messages to"]);

        return -1;
    }

    NSString *appId = [launchSession.rawData objectForKey:@"webAppId"];

    if (!appId)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid LaunchSession to send messages to"]);

        return -1;
    }

    if (_socket == nil)
        [self openSocket];

    int callId = [self getNextId];

    NSDictionary *payload = @{
            @"type" : @"p2p",
            @"to" : appId,
            @"payload" : message
    };

    ServiceCommand *comm = [ServiceCommand commandWithDelegate:nil target:nil payload:payload];
    comm.callbackComplete = success;
    comm.callbackError = failure;

    [_activeConnections setObject:comm forKey:[NSString stringWithFormat:@"req%d",callId]];

    NSString *sendString = [self writeToJSON:payload];

    if (_socket.readyState == LGSR_OPEN)
    {
        [_socket send:sendString];

        if ([_commandQueue containsObject:sendString])
            [_commandQueue removeObject:sendString];
    } else if (_socket.readyState == LGSR_CONNECTING ||
            _socket.readyState == LGSR_CLOSING)
    {
        [_commandQueue addObject:sendString];
    } else
    {
        [_commandQueue addObject:sendString];
        [self openSocket];
    }

    return callId;
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

        NSUInteger i = 0;
        for (i = 0; i < _keyboardQueue.count; i++)
        {
            if (![[_keyboardQueue firstObject] isEqualToString:kKeyboardDelete])
                break;
        }

        NSRange deleteRange = NSMakeRange(0, i);
        [_keyboardQueue removeObjectsInRange:deleteRange];

        [payload setObject:@(i) forKey:@"count"];
    } else
    {
        target = @"ssap://com.webos.service.ime/insertText";
        NSMutableString *stringToSend = [[NSMutableString alloc] init];

        NSUInteger i = 0;
        for (i = 0; i < _keyboardQueue.count; i++)
        {
            NSString *text = [_keyboardQueue objectAtIndex:i];

            if (![text isEqualToString:kKeyboardEnter] && ![text isEqualToString:kKeyboardDelete])
                [stringToSend appendString:text];
            else
                break;
        }

        NSRange textRange = NSMakeRange(0, i);
        [_keyboardQueue removeObjectsInRange:textRange];

        [payload setObject:stringToSend forKey:@"text"];
        [payload setObject:@(NO) forKey:@"replace"];
    }

    NSURL *URL = [NSURL URLWithString:target];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self target:URL payload:payload];
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

    ServiceSubscription *subscription = [self addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
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

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:[NSURL URLWithString:@"ssap://system.notifications/createToast"] payload:toastParams];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - System info

- (void)getServiceListWithSuccess:(ServiceListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://api/getServiceList"];

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self target:URL payload:nil];
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

    ServiceCommand *command = [ServiceCommand commandWithDelegate:self target:URL payload:nil];
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
