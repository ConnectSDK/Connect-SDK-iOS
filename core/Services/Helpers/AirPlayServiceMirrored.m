//
//  AirPlayServiceMirrored.m
//  Connect SDK
//
//  Created by Jeremy White on 5/28/14.
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

#import "AirPlayServiceMirrored.h"
#import <AVFoundation/AVPlayerItem.h>
#import <AVFoundation/AVAsset.h>
#import "ConnectError.h"
#import "AirPlayWebAppSession.h"
#import "ConnectUtil.h"
#import "AirPlayService.h"

#import "NSObject+FeatureNotSupported_Private.h"

/*credit : http://stackoverflow.com/questions/30040055/uiviewcontroller-displayed-sideways-on-airplay-screen-when-launched-from-landsca/30355853#30355853
 
 Added to AirPlayServiceWindow interface to override isKeyWindow method & AirPlayServiceViewController to override shouldAutorotate method to fix issue where web app is dsiplayed sideways when launched in landscape.
 */

@interface AirPlayServiceWindow : UIWindow
@end

@implementation AirPlayServiceWindow

- (BOOL)isKeyWindow {
    return NO;
}

@end

@interface AirPlayServiceViewController : UIViewController
@end

@implementation AirPlayServiceViewController

- (BOOL)shouldAutorotate {
    return NO;
}
@end

@interface AirPlayServiceMirrored () <ServiceCommandDelegate, WKNavigationDelegate, UIAlertViewDelegate>

@property (nonatomic, copy) SuccessBlock launchSuccessBlock;
@property (nonatomic, copy) FailureBlock launchFailureBlock;

@property (nonatomic) AirPlayWebAppSession *activeWebAppSession;
@property (nonatomic) ServiceSubscription *playStateSubscription;

@end

@implementation AirPlayServiceMirrored
{
    NSTimer *_connectTimer;
    UIAlertView *_connectingAlertView;
}

- (instancetype) initWithAirPlayService:(AirPlayService *)service
{
    self = [super init];

    if (self)
    {
        _service = service;
    }

    return self;
}

- (void) connect
{
    [self checkForExistingScreenAndInitializeIfPresent];

    if (self.secondWindow && self.secondWindow.screen)
    {
        _connecting = NO;
        _connected = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hScreenDisconnected:) name:UIScreenDidDisconnectNotification object:nil];

        if (self.service.connected && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
            dispatch_on_main(^{ [self.service.delegate deviceServiceConnectionSuccess:self.service]; });
    } else
    {
        _connected = NO;
        _connecting = YES;

        [self checkScreenCount];

        NSString *title = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_Title" value:@"Mirroring Required" table:@"ConnectSDK"];
        NSString *message = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_Description" value:@"Enable AirPlay mirroring to connect to this device" table:@"ConnectSDK"];
        NSString *ok = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_OK" value:@"OK" table:@"ConnectSDK"];
        NSString *cancel = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_AirPlay_Mirror_Cancel" value:@"Cancel" table:@"ConnectSDK"];

        _connectingAlertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hScreenConnected:) name:UIScreenDidConnectNotification object:nil];

        if (self.service && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceService:pairingRequiredOfType:withData:)])
            dispatch_on_main(^{ [self.service.delegate deviceService:self.service pairingRequiredOfType:DeviceServicePairingTypeAirPlayMirroring withData:_connectingAlertView]; });
    }
}

- (void) disconnect
{
    _connected = NO;
    _connecting = NO;

    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];

    if (self.secondWindow)
    {
        _secondWindow.hidden = YES;
        _secondWindow.screen = nil;
        _secondWindow = nil;
    }

    if (_connectTimer)
    {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }

    if (_connectingAlertView)
        dispatch_on_main(^{ [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO]; });

    if (self.service && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        [self.service.delegate deviceService:self.service disconnectedWithError:nil];
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    _connectingAlertView.delegate = nil;
    _connectingAlertView = nil;

    if (buttonIndex == 0 && _connecting)
        [self disconnect];
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeUnsubscribe)
    {
        if (subscription == self.playStateSubscription)
        {
            [[self.playStateSubscription successCalls] removeAllObjects];
            [[self.playStateSubscription failureCalls] removeAllObjects];
            [self.playStateSubscription setIsSubscribed:NO];
            self.playStateSubscription = nil;
        }
    }

    return -1;
}

#pragma mark - External display detection, setup

- (void) checkScreenCount
{
    if (_connectTimer)
    {
        [_connectTimer invalidate];
        _connectTimer = nil;
    }

    if (!self.connecting)
        return;

    if ([UIScreen screens].count > 1)
    {
        _connecting = NO;
        _connected = YES;

        if (_connectingAlertView)
            dispatch_on_main(^{ [_connectingAlertView dismissWithClickedButtonIndex:1 animated:NO]; });

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hScreenDisconnected:) name:UIScreenDidDisconnectNotification object:nil];

        if (self.service.connected && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
            dispatch_on_main(^{ [self.service.delegate deviceServiceConnectionSuccess:self.service]; });
    } else
    {
        _connectTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkScreenCount) userInfo:nil repeats:NO];
    }
}

- (void)checkForExistingScreenAndInitializeIfPresent
{
    if ([[UIScreen screens] count] > 1)
    {
        UIScreen *secondScreen = [[UIScreen screens] objectAtIndex:1];

        CGRect screenBounds = secondScreen.bounds;

        _secondWindow = [[AirPlayServiceWindow alloc] initWithFrame:screenBounds];
        _secondWindow.screen = secondScreen;

        DLog(@"Displaying content with bounds %@", NSStringFromCGRect(screenBounds));
    }
}

- (void) hScreenConnected:(NSNotification *)notification
{
    DLog(@"%@", notification);

    if (!self.secondWindow)
        [self checkForExistingScreenAndInitializeIfPresent];

    [self checkScreenCount];
}

- (void) hScreenDisconnected:(NSNotification *)notification
{
    DLog(@"%@", notification);

    if (_connecting || _connected)
        [self disconnect];
}

#pragma mark - WebAppLauncher

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
    [self launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId params:params relaunchIfRunning:YES success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app URL"]);

        return;
    }

    [self checkForExistingScreenAndInitializeIfPresent];

    if (!self.secondWindow || !self.secondWindow.screen)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not detect a second screen -- make sure you have mirroring enabled"]);

        return;
    }

    if (_webAppWebView)
    {
        if (relaunchIfRunning)
        {
            [self closeWebApp:nil success:^(id responseObject)
                    {
                        [self launchWebApp:webAppId params:params relaunchIfRunning:relaunchIfRunning success:success failure:failure];
                    } failure:failure];

            return;
        } else
        {
            NSString *webAppHost = _webAppWebView.URL.host;

            if ([webAppId rangeOfString:webAppHost].location != NSNotFound)
            {
                if (params && params.count > 0)
                {
                    [self.activeWebAppSession connectWithSuccess:^(id connectResponseObject)
                            {
                                [self.activeWebAppSession sendJSON:params success:^(id sendResponseObject)
                                        {
                                            if (success)
                                                success(self.activeWebAppSession);
                                        } failure:failure];
                            } failure:failure];
                } else
                {
                    if (success)
                        dispatch_on_main(^{ success(self.activeWebAppSession); });
                }

                return;
            }
        }
    }

    DLog(@"Created a web view with bounds %@", NSStringFromCGRect(self.secondWindow.bounds));

    WKProcessPool *commonProcessPool = [[WKProcessPool alloc] init];
    WKWebViewConfiguration *webViewConfig = [[WKWebViewConfiguration alloc] init];
    webViewConfig.processPool = commonProcessPool;
    webViewConfig.allowsInlineMediaPlayback = true;
    webViewConfig.mediaPlaybackAllowsAirPlay = false;
    webViewConfig.mediaPlaybackRequiresUserAction = false;

    _webAppWebView = [[WKWebView alloc] initWithFrame:self.secondWindow.bounds configuration:webViewConfig];

    AirPlayServiceViewController *secondScreenViewController = [[AirPlayServiceViewController alloc] init];
    secondScreenViewController.view = _webAppWebView;
    _webAppWebView.navigationDelegate = self;
    self.secondWindow.rootViewController = secondScreenViewController;
    self.secondWindow.hidden = NO;

    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self.service;

    AirPlayWebAppSession *webAppSession = [[AirPlayWebAppSession alloc] initWithLaunchSession:launchSession service:self.service];
    self.activeWebAppSession = webAppSession;

    __weak AirPlayWebAppSession *weakSession = self.activeWebAppSession;

    if (params && params.count > 0)
    {
        self.launchSuccessBlock = ^(id launchResponseObject)
        {
            [weakSession connectWithSuccess:^(id connectResponseObject)
                    {
                        [weakSession sendJSON:params success:^(id sendResponseObject)
                                {
                                    if (success)
                                        success(weakSession);
                                } failure:failure];
                    } failure:failure];
        };
    } else
    {
        self.launchSuccessBlock = ^(id responseObject)
        {
            if (success)
                success(weakSession);
        };
    }

    self.launchFailureBlock = failure;

    NSURL *URL = [NSURL URLWithString:webAppId];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];

    [self.webAppWebView loadRequest:request];
}

- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void) joinWebApp:(LaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (self.webAppWebView && self.connected)
    {
        NSString *webAppHost = self.webAppWebView.URL.host;

        if ([webAppLaunchSession.appId rangeOfString:webAppHost].location != NSNotFound)
        {
            AirPlayWebAppSession *webAppSession = [[AirPlayWebAppSession alloc] initWithLaunchSession:webAppLaunchSession service:self.service];
            self.activeWebAppSession = webAppSession;

            [webAppSession connectWithSuccess:success failure:failure];
        } else
        {
            if (failure)
                dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Web is not currently running"]); });
        }
    } else
    {
        if (failure)
            dispatch_on_main(^{ failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Web is not currently running"]); });
    }
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    LaunchSession *launchSession = [LaunchSession launchSessionForAppId:webAppId];
    launchSession.service = self.service;
    launchSession.sessionType = LaunchSessionTypeWebApp;

    [self joinWebApp:launchSession success:success failure:failure];
}

- (void) disconnectFromWebApp
{
    if (self.activeWebAppSession)
    {
        if (self.activeWebAppSession.delegate && [self.activeWebAppSession.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
            dispatch_on_main(^{ [self.activeWebAppSession.delegate webAppSessionDidDisconnect:self.activeWebAppSession]; });

        self.activeWebAppSession = nil;
    }

    self.launchSuccessBlock = nil;
    self.launchFailureBlock = nil;
}

- (void) closeWebApp:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self disconnectFromWebApp];

    if (_secondWindow)
    {
        _secondWindow.rootViewController = nil;
        _secondWindow.hidden = YES;
        _secondWindow.screen = nil;
        _secondWindow = nil;

        _webAppWebView.navigationDelegate = nil;
        _webAppWebView = nil;
    }

    if (success)
        success(nil);
}

- (void) pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

-(void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (ServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    return [self sendNotSupportedFailure:failure];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLog(@"%@", error.localizedDescription);

    if (self.launchFailureBlock)
        self.launchFailureBlock(error);

    self.launchSuccessBlock = nil;
    self.launchFailureBlock = nil;
}

- (BOOL)webView:(WKWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
{
    if ([request.URL.absoluteString hasPrefix:@"connectsdk://"])
    {
        NSString *jsonString = [[request.URL.absoluteString componentsSeparatedByString:@"connectsdk://"] lastObject];
        jsonString = [ConnectUtil urlDecode:jsonString];

        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        NSError *jsonError;
        id messageObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];

        if (jsonError || !messageObject)
            messageObject = jsonString;

        DLog(@"Got p2p message from web app:\n%@", messageObject);

        if (self.activeWebAppSession)
        {
            NSString *webAppHost = self.webAppWebView.URL.host;

            // check if current running web app matches the current web app session
            if ([self.activeWebAppSession.launchSession.appId rangeOfString:webAppHost].location != NSNotFound)
            {
                dispatch_on_main(^{
                    if (self.activeWebAppSession)
                        self.activeWebAppSession.messageHandler(messageObject);
                });
            } else
                [self.activeWebAppSession disconnectFromWebApp];
        }

        return NO;
    } else
    {
        return YES;
    }
}

- (void)webViewDidFinishLoad:(WKWebView *)webView
{
    DLog(@"%@", webView.request.URL.absoluteString);

    if (self.launchSuccessBlock)
        self.launchSuccessBlock(nil);

    self.launchSuccessBlock = nil;
    self.launchFailureBlock = nil;
}

- (void)webViewDidStartLoad:(WKWebView *)webView
{
    DLog(@"%@", webView.request.URL.absoluteString);
}

@end
